from time import strftime, gmtime


def printlog(*args):
    """
    Helper function to print string or list of strings
    :param args: any String args
    """
    current = strftime("%Y-%m-%d %H:%M:%SZ", gmtime())
    print(current, *args)


def string_to_bool(s):
    """
    Helper function to convert any strings of those to be true

    We have different way to say yes!"

    :param s: input
    :type s: str
    :return: True or False
    :rtype: bool
    """

    if s.lower() in ["true", "t", "yes", "yeah", "yup", "y", "certainly",
                     "sure", "1"]:
        return True
    else:
        return False
