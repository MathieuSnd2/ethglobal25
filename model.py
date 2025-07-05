



import math

# token to share ratio
r = [1, 2]

# cmd weight = share allocation
w = [0.5, 0.5]

# token allocation
a = [w[i] / r[i]   for i in range(len(r))]
a = [a[i] / sum(a) for i in range(len(r))]

for ai in a:
    assert ai <= 1

# received tokens
tsum = 10
t = [a[i] * tsum for i in range(len(a))]


def token2shares(r, t):
    return [r[i] * t[i] for i in range(len(r))]


s = token2shares(r,t)


def value(s, r):
    return [s[i]/r[i] for i in range(len(a))]



print('initial tokens: ', tsum)
print('token weight: ', a)
print('share weight: ', w)
print('shares: ', s)
print('ssum:  ', sum(s))
print('value:  ', value(s, r))
print('vsum:  ', sum(value(s, r)))

