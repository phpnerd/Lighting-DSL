#!/usr/bin/python3

#
# Copyright (c) Thomas Nägele and contributors. All rights reserved.
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

import argparse, asyncio

from models import CloudNodeSet, BenchmarkSet

parser = argparse.ArgumentParser(description='CoHLA Distributed Execution Tool')
parser.add_argument('-n', '--nodes', metavar='NodesConfigurationFile', type=str, dest='nodes',
                    help='Configuration file for nodes.', required=True)
parser.add_argument('-b', '--benchmarks', metavar='BenchmarkFile', type=str, dest='benchmarks',
                    help='Configuration file for benchmarks to run.', required=True)
parser.add_argument('-o', '--output', metavar='OutputFile', required=False, type=str, dest='output',
                    help='Output file to write the results to.', default=None)
parser.add_argument('--no-install', dest='noInstall', help='Set if installation can be skipped',
                    action='store_const', const=True, default=False)
parser.add_argument('-q', '--quiet', dest='quiet', help='Set if execution should be quiet.',
                    action='store_const', const=True, default=False)
args = parser.parse_args()


def read_file(filename):
    try:
        in_file = open(filename)
        file_contents = in_file.readlines()
        in_file.close()
        file_contents = [l.strip() for l in file_contents]
        file_contents = list(filter(lambda l: not l.strip().startswith('#'), file_contents))
        return True, file_contents
    except FileNotFoundError:
        print('File ' + filename + ' does not exist!')
        return False, []


# main sequence

success, nodeFileContents = read_file(args.nodes)
if not success:
    exit(-1)
success, benchFileContents = read_file(args.benchmarks)
if not success:
    exit(-1)
nodeSet = CloudNodeSet(nodeFileContents)
benchmarkSet = BenchmarkSet(benchFileContents, args.output)

print('Connecting...')
nodeSet.connect()
print('Initialising...')
nodeSet.init(benchmarkSet, skip_install=args.noInstall, quiet=args.quiet)
print('Initialisation finished')
benchmarkSet.run(nodeSet)
print('Finished')
nodeSet.disconnect()

print('\n===== RESULTS =====')
benchmarkSet.print_results()
print('===================')
