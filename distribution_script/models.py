import threading, paramiko, time, re


def parse_key_value(line, key=None):
    spl = line.split(':', maxsplit=1)
    if len(spl) != 2:
        print('Invalid KeyValuePair: ' + str(line))
        return None
    if key is not None and spl[0] != key:
        print('Invalid Key: ' + spl[0] + ' found, expected ' + key)
        return None
    return spl[1].strip()


def wait_for(input, keyword=None, prepend=None, quiet=False):
    while True:
        line = input.readline().strip()
        if not quiet and len(line) > 0:
            print(('[' + prepend + '] ' if prepend is not None else '') + line)
        if keyword is not None and line == keyword:
            return True if keyword is not None else None


def find_outliers(results):
    outliers = []
    if len(results) >= 3:
        for result in results:
            rest_avg = (sum(results) - result) / (len(results) - 1)
            if result < 0.75 * rest_avg or result > 1.25 * rest_avg:
                outliers.append(result)
    return outliers


class CloudNodeSet:
    nodes = {}

    def __init__(self, lines):
        self.nodes = {}
        self.parse(lines)

    def __repr__(self):
        return str(len(self.nodes)) + ' cloud nodes (' + str(
            len(list(filter(lambda n: n.is_connected(), self.nodes.values())))) + ' connected)'

    def parse(self, lines):
        nodes = [CloudNode(line.split(';')) for line in lines]
        for node in nodes:
            self.nodes[node.name] = node

    def connect(self):
        for node in self.nodes.values():
            node.connect()

    def disconnect(self):
        for node in self.nodes.values():
            node.disconnect()

    def init(self, benchmark_set, skip_install=False, quiet=False):
        threads = {}
        for node in self.nodes.values():
            threads[node.name] = threading.Thread(target=node.init,
                                                  args=(benchmark_set.source, benchmark_set.path, skip_install, quiet))
        for thread in threads.values():
            thread.start()
        for thread in threads.values():
            thread.join()


class CloudNode:
    name = None
    hostname = None
    internal_hostname = None
    port = None
    username = None
    password = None
    connection = None
    ready = False
    single_speed = []

    def __init__(self, line):
        self.parse(line)
        self.connection = Connection(self.name)
        self.single_speed = []

    def __repr__(self):
        return self.name + ': ' + str('Connected' if self.connection.is_connected() else 'Disconnected')

    def parse(self, line):
        if len(line) == 6:
            self.name = line[0]
            self.hostname = line[1]
            self.port = int(line[2])
            self.username = line[3]
            self.password = line[4]
            self.internal_hostname = line[5]

    def connect(self):
        self.connection.connect(self.hostname, self.port, self.username, self.password)

    def disconnect(self):
        self.connection.close()
        print(self.name + ' disconnected')

    def init(self, source, path, skip_install=False, quiet=False):
        self.ready = self.connection.init(source, path, skip_install, quiet)
        print(self.name + ' ' + ('initialised' if self.ready else 'failed to initialise'))
        return self.ready

    def is_connected(self):
        return self.connection.is_connected()

    def is_ready(self):
        return self.ready

    def block(self):
        self.ready = False

    def release(self):
        self.ready = True

    def add_speed(self, speed):
        self.single_speed.append(speed)
        outliers = find_outliers(self.single_speed)
        for outlier in outliers:
            self.single_speed.remove(outlier)

    def get_speed(self):
        if len(self.single_speed) == 0:
            return 0.0
        return sum(self.single_speed) / len(self.single_speed)

    def exec(self, *cmd, keyword=None):
        return self.connection.cmd(*cmd, keyword=keyword)

    def write(self, word):
        return self.connection.write(word)

    def wait_result(self):
        return self.connection.wait_result()


class Connection:
    name = None
    client = None
    connected = False
    error = None

    cmd_buffer = []
    stdin = None
    stdout = None
    stderr = None

    err_thread = None

    def __init__(self, name):
        self.name = name
        self.cmd_buffer = []
        self.client = paramiko.SSHClient()
        self.client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    def connect(self, host, port, user, password):
        try:
            self.client.connect(hostname=host, port=port, username=user, password=password, banner_timeout=10, timeout=7200)
            print(self.name + ' connected')
            self.connected = True
        except paramiko.AuthenticationException:
            self.error = 'Authentication failed'
        except paramiko.SSHException:
            self.error = 'SSH exception'

    def close(self):
        if self.connected:
            self.client.close()
            self.connected = False

    def init(self, source, path, skip_install=False, quiet=False):
        if self.connected:
            b = True
            self.cmd_buffer.append('cd ~/')
            self.cmd_buffer.append('if [ ! -f dist.tar.gz ]; then wget -Lq -O dist.tar.gz ' + source + '; fi')
            self.cmd_buffer.append('if [ ! -f install.sh ]; then tar xf dist.tar.gz; fi')
            if not skip_install:
                self.cmd_buffer.append('./install.sh')
                b = self.exec('Done!', quiet=quiet)
            if b:
                self.cmd_buffer.append('cd ~/' + path)
                self.cmd_buffer.append('./run.py -b')
                return self.exec('Finished building.', quiet=quiet)
            return b
        return False

    def cmd(self, *cmd, keyword=None, quiet=True):
        self.cmd_buffer += list(cmd)
        return self.exec(keyword, quiet=quiet)

    def exec(self, keyword=None, quiet=True):
        self.stdin, self.stdout, self.stderr = self.client.exec_command(' && '.join(self.cmd_buffer))
        if self.err_thread is None:
            self.err_thread = threading.Thread(target=wait_for, args=(self.stderr, None, self.name))
            self.err_thread.daemon = True
            self.err_thread.start()
        self.cmd_buffer = []
        if keyword is not None:
            return wait_for(self.stdout, keyword=keyword, prepend=self.name, quiet=quiet)
        return True

    def write(self, word):
        d = self.stdin.write(word)
        self.stdin.flush()
        return d

    def wait_result(self, quiet=True):
        regex = re.compile('Simulation time: (\d+(.\d+)?) s')
        while True:
            line = self.stdout.readline().strip()
            if not quiet:
                print('[' + self.name + '] ' + line)
            if regex.match(line):
                return float(regex.findall(line)[0][0])

    def is_connected(self):
        return self.connected


class BenchmarkSet:
    source = None
    path = None
    topology = None
    situation = None
    scenario = None
    measure_time = None
    output_path = None
    runs = 1
    benchmarks = []
    node_set = None

    initialised = False
    threads = {}

    def __init__(self, lines, output_path):
        self.output_path = output_path
        self.threads = {}
        self.parse(lines)

    def __repr__(self):
        if self.initialised:
            return str(len(self.benchmarks)) + ' benchmarks for ' + self.source
        return 'BenchmarkSet not initialised'

    def parse(self, lines):
        if len(lines) < 7:
            return
        self.source = parse_key_value(lines[0], 'source')
        self.path = parse_key_value(lines[1], 'path')
        self.topology = parse_key_value(lines[2], 'topology')
        self.situation = parse_key_value(lines[3], 'situation')
        self.scenario = parse_key_value(lines[4], 'scenario')
        self.measure_time = float(parse_key_value(lines[5], 'measuretime'))
        self.runs = int(parse_key_value(lines[6], 'runs'))
        if not (
                self.source is None or self.path is None or self.topology is None or self.situation is None or self.scenario is None):
            if len(lines) >= 8:
                self.benchmarks = [Benchmark(line, self.runs) for line in lines[7:]]
            self.initialised = True

    def is_initialised(self):
        return self.initialised

    def print_results(self):
        for benchmark in self.benchmarks:
            print(benchmark.name + ': ' + ', '.join([str(r) for r in benchmark.results]) + ' s' + (' (' + str(sum(benchmark.results) / len(benchmark.results)) + ' s)' if len(benchmark.results) > 1 else ''))

    def to_csv(self):
        header = 'Benchmark;#Nodes;Automatic;'
        header += ';'.join([node for node in self.node_set.nodes]) + ';'
        header += 'MinNodeSpeed;MaxNodeSpeed;AvgNodeSpeed;MinSpeed;MaxSpeed;AvgSpeed;MinSpeedUp;MaxSpeedUp;AvgSpeedUp;'
        header += ';'.join(['Run ' + str(i) for i in range(1, self.runs + 1)])
        lines = [header]
        for benchmark in self.benchmarks:
            sim_times = [self.node_set.nodes[node].get_speed() for node in benchmark.nodes]
            if len(benchmark.results) > 0:
                average = sum(benchmark.results) / len(benchmark.results)
                slowest_node = max(sim_times)
                fastest_node = min(sim_times)
                avg_node = sum(sim_times) / len(sim_times)
                line = benchmark.name + ';' + str(len(benchmark.nodes)) + ';' + (str(benchmark.distribution is None)) + ';'
                line += ';'.join(['X' if node == benchmark.nodes[0] else 'x' if node in benchmark.nodes else '' for node in self.node_set.nodes]) + ';'
                line += str(slowest_node) + ';'
                line += str(fastest_node) + ';'
                line += str(avg_node) + ';'
                line += str(max(benchmark.results)) + ';'
                line += str(min(benchmark.results)) + ';'
                line += str(average) + ';'
                line += str(fastest_node / average) + ';'
                line += str(slowest_node / average) + ';'
                line += str(avg_node / average) + ';'
                line += ';'.join([str(result) for result in benchmark.results])
                lines.append(line)
        return lines

    def write_csv(self):
        if self.output_path is None:
            return
        with open(self.output_path, 'w') as f:
            if f.writable():
                f.writelines([line + '\n' for line in self.to_csv()])

    def next(self, node_set):
        benchmarks = list(filter(lambda benchmark: benchmark.runs > 0 and benchmark.runnable(node_set.nodes), self.benchmarks))
        if len(benchmarks) > 0:
            min_nodes_benchmark = min(benchmarks, key=Benchmark.get_nr_of_nodes)
            if min_nodes_benchmark.nr_of_nodes == 1:
                return min_nodes_benchmark
            return max(benchmarks, key=Benchmark.get_nr_of_nodes)
        return None

    def finished(self):
        return all([benchmark.runs == 0 for benchmark in self.benchmarks])

    def runs_to_go(self):
        return sum([benchmark.runs for benchmark in self.benchmarks]), self.runs * len(self.benchmarks)

    def run(self, node_set):
        self.node_set = node_set
        while not self.finished():
            benchmark = self.next(node_set)
            if benchmark is not None:
                if not benchmark.is_assigned():
                    benchmark.assign(node_set.nodes)
                    for _benchmark in self.benchmarks: # Also set similar distributions to use these nodes
                        if _benchmark.nr_of_nodes == benchmark.nr_of_nodes and _benchmark.name != benchmark.name:
                            _benchmark.assign(node_set.nodes)
                for node_name in benchmark.nodes:
                    node_set.nodes[node_name].block()
                to_go, total = self.runs_to_go()
                print('Progress: ' + str(total - to_go) + '/' + str(total) + ' (' + str((total - to_go) / total * 100) + ' %)')
                self.threads[benchmark.name] = threading.Thread(target=benchmark.run,
                                                                args=(self, node_set))
                self.threads[benchmark.name].start()
            time.sleep(1)


class Benchmark:
    name = None
    distribution = None
    nr_of_nodes = 0
    nodes = []
    runs = 1
    results = []

    def __init__(self, line, runs):
        self.runs = runs
        self.results = []
        self.parse(line)

    def __repr__(self):
        return self.name if self.name is not None else 'NONAME'

    def parse(self, line):
        spl = line.split(';')
        if len(spl) >= 3:
            self.name = spl[0]
            if spl[1] != 'AUTO':
                self.distribution = spl[1]
            self.nr_of_nodes = int(spl[2])
            self.nodes = [node.strip() for node in spl[3:]]

    def is_assigned(self):
        return len(self.nodes) == self.nr_of_nodes

    def assign(self, nodes):
        if len(self.nodes) == 0:
            self.nodes = self.find_available_nodes(nodes)
            print(self.name + ' assigned to nodes ' + ', '.join(self.nodes))

    def find_available_nodes(self, nodes):
        available_nodes = []
        for node_name, node in nodes.items():
            if node.is_ready():
                available_nodes.append(node_name)
        if len(available_nodes) < self.nr_of_nodes:
            return []
        return available_nodes[0:self.nr_of_nodes]

    def runnable(self, nodes):
        if not self.is_assigned():
            return len(self.find_available_nodes(nodes)) == self.nr_of_nodes
        return all([nodes[node].is_ready() for node in self.nodes])

    def run(self, benchset, node_set):
        print('Now running ' + self.name + ' on nodes ' + ', '.join(self.nodes))
        running_nodes = []
        node_id = 0
        parent_host = None
        for node_name in self.nodes:
            node = node_set.nodes[node_name]
            command = './run.py -e -t ' + benchset.topology + ' -s ' + benchset.situation + ' -u ' + benchset.scenario
            if benchset.measure_time >= 0.0:
                command += ' --loggerMeasureTime ' + str(benchset.measure_time)
            if len(self.nodes) > 1:
                if node_id == 0:
                    parent_host = node.internal_hostname
                if self.distribution is None:
                    command += ' --nrOfSystems ' + str(len(self.nodes))
                else:
                    command += ' --distribution ' + self.distribution
                if node_id > 0:
                    command += ' --parentHost ' + parent_host
                command += ' --systemId ' + str(node_id)
                node_id += 1
            running_nodes.append(node)
            node.exec('cd ' + benchset.path, command, keyword='Press [ENTER] to start the simulations...')
        for node in running_nodes[1:] + [running_nodes[0]]:
            node.write('\n')
        result = running_nodes[0].wait_result()
        self.results.append(result)
        if len(self.nodes) == 1:
            running_nodes[0].add_speed(result)
        for node in running_nodes[1:]:
            node.exec('pkill -2 run.py')
        self.check_results()
        benchset.write_csv()
        self.runs -= 1
        time.sleep(2)
        for node in running_nodes:
            node.release()
        print('Finished ' + self.name + ' (' + str(self.runs) + ' runs to go)')

    def check_results(self):
        outliers = find_outliers(self.results)
        for outlier in outliers:
            self.results.remove(outlier)
            self.runs += 1
            print('Removed outlier in ' + self.name + ': ' + str(outlier))

    def get_nr_of_nodes(self):
        return self.nr_of_nodes
