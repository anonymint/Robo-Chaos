from time import strftime, gmtime


def printlog(*args):
    """
    Helper function to print string or list of strings
    :param args: any String args
    """
    current = strftime("%Y-%m-%d %H:%M:%SZ", gmtime())
    print(current, *args)
