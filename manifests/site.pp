node default {
  notify { "Something is most likely wrong with your site.pp file for ${hostname} because you are not getting a specific setup": }
}
node /^puppet\..*/ {
  include vagrant_puppetdb
}


