#!/usr/bin/python
"""
This file contains the driver and methods for running a random grid search for Tuffy models
"""




def _load_args(args):
    executable = args.pop(0)
    if len(args) != 1 or ({'h', 'help'} & {arg.lower().strip().replace('-', '') for arg in args}):
        print("USAGE: python3 {} <method>".format(executable), file = sys.stderr)
        sys.exit(1)

    method = args.pop(0)

    return method


if (__name__ == '__main__'):
    method = _load_args(sys.argv)
    main(method)