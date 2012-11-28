import sys,re

if __name__ == '__main__':
  fn_qun = open(sys.argv[1])
  
  for line in fn_qun:
      fields = line.rstrip().lower().split('\t')
      if len(fields) < 2: continue
      num = int(fields[1])/30 + 2
      i = 1
      while (i < num ):
        print 'https://github.com/search?l=%s&p=%d&q=location|china&repo=&type=Users' % (fields[0],i)
        i = i + 1
