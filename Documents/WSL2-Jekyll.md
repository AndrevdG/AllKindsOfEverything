> Not a complete instruction, but a reminder of how to update and start jekyll in WSL in order to edit and test website locally before uploading. 
> I always forget and have to look it up in the WSL history...

It is possible to run a webpage or blog using static webpages (so no dynamic code), but compile these dynamically using for instance github actions. 
There are likely many ways to do this, but in my case I am using Jekyll to generate the webpages. jekyll allows you to create pages using MarkDown, which is
relatively easy way to get pages formatted. It also allows you run the website locally, either in linux or in my case WSL. This way pages can be 
previewed on the fly before uploading.

Some example documentation:
_I don't speciffically remember what I used exactly to get started, but for sure the Jekyll documentation. These links are merely provided in case someone happens
onto this page and would like to know more_
- [Jekyll Quickstart](https://jekyllrb.com/docs/)
- [Micrsoft Learn Turotial: Publish a Jekyll site to Azure Static Web Apps](https://learn.microsoft.com/en-us/azure/static-web-apps/publish-jekyll)


The real goal of this document is really to remind myself how to update Jekyll and start it locally:

```bash
  cd /mnt/d/git/www_automagical_eu/
  cd jekyll-blog/
  bundle update
  bundle exec jekyll serve --drafts --force_polling
```

For help with updating Ruby, check [ruby - install and upgrade (Michael Currin)](**https://github.com/MichaelCurrin/learn-to-code/blob/master/en/topics/scripting_languages/Ruby/README.md#install-and-upgrade**)
