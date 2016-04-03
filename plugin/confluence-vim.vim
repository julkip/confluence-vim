if !has('python')
    echo "Error: Required vim compiled with +python"
    finish
endif

function! OpenConfluencePage(url)

python << EOF
import json
import html2text
import requests
import re
import vim

cb = vim.current.buffer

# confluence_url should be defined in the .vimrc file
instance = vim.eval("g:confluence_url")
url = vim.eval("a:url")

try:
    from urlparse import urlparse
    space_name = urlparse(url).netloc
    article_path = urlparse(url).path

    try:
      parent_page= article_path.split("/")[-2]
      article_name = article_path.split("/")[-1]

      vim.command("let b:article_name =  '%s'" % article_name)
      vim.command("let b:space_name = '%s'" %   space_name)

      if not parent_page:
        #Seems like there is no parent => we are creating the page directly below the SPACE Home page
        rp = requests.get(instance , params={'spaceKey': space_name,  'status': 'current', 'expand': 'body.view,version.number,ancestors', 'limit': 1, 'type': 'page', 'start': 0})
      else:
        #Get the parent page
        rp = requests.get(instance , params={'spaceKey': space_name, 'title': parent_page, 'status': 'current', 'expand': 'body.view,version.number,ancestors', 'limit': 1})
      parent_resp = json.loads(rp.text)['results']

      vim.command("let b:parent_pageid = %d" % int(parent_resp[0]['id']))

      r = requests.get(instance , params={'spaceKey': space_name, 'title': article_name, 'status': 'current', 'expand': 'body.view,version.number,ancestors', 'limit': 1})

      resp = json.loads(r.text)['results']
      if len(resp) > 0:
          vim.command("let b:confid = %d" % int(resp[0]['id']))
          vim.command("let b:confv = %d" % int(resp[0]['version']['number']))

          article = resp[0]['body']['view']['value']
          h = html2text.HTML2Text()
          h.body_width = 0
          article_markdown = h.handle(article)

          del cb[:]
          for line in article_markdown.split('\n'):
              cb.append(line.encode('utf8'))
          del cb[0]
      else:
          vim.command("let b:confid = 0")
          vim.command("let b:confv = 0")
          vim.command("echo \"New confluence entry - %s\"" % article_name)
      vim.command("set filetype=mkd")
    except IndexError, e:
      print "Space- or articlename is missing, please use conf://<SPACENAME>/<PAGENAME> "
except AttributeError, e:
    print "Space- or articlename is missing, please use conf://<SPACENAME>/<PAGENAME> "

EOF
endfunction

function! WriteConfluencePage(url)
python << EOF
import json
import markdown
import requests
import re
import vim

cb = vim.current.buffer
#Get the stored valued
instance = vim.eval("g:confluence_url")
article_name = str(vim.eval("b:article_name"))
space_name = str(vim.eval("b:space_name"))
article_id = int(vim.eval("b:confid"))
parent_pageid = int(vim.eval("b:parent_pageid"))
article_v = int(vim.eval("b:confv")) + 1
article_content = markdown.markdown("\n".join(cb))

if article_id > 0:
  jj = {"id": str(article_id), "title": article_name, "type": "page", "space": { "key": space_name }, "version": { "number": article_v }, "ancestors":[{"id": parent_pageid }], "body": { "storage": { "value": article_content, "representation": "storage" } } }
  r = requests.put('%s/%d' % (instance, article_id), data=json.dumps(jj), verify=True, headers={"content-type":"application/json"})
else:
  jj = {"type": "page", "space": {"key": space_name}, "title": article_name, "ancestors": [{"id": parent_pageid }], "body": {"storage": {"value": article_content, "representation": "storage"}}}
  r = requests.post('%s' % instance, data=json.dumps(jj), verify=True, headers={"content-type":"application/json"})
  resp = json.loads(r.text)
  vim.command("let b:confid = %d" % int(resp['id']))
  vim.command("let b:confv = %d" % int(resp['version']['number']))
  vim.command("let &modified = 0")
  vim.command("echo \"Confluence entry %s written.\"" % article_name)
EOF
endfunction

augroup Confluence
  au!
  au BufReadCmd conf://*  call OpenConfluencePage(expand("<amatch>"))
  au BufWriteCmd conf://*  call WriteConfluencePage(expand("<amatch>"))
augroup END

