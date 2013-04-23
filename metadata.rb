name             "graphite"
maintainer       "stwind"
maintainer_email "stwindfy@gmail"
license          "Apache 2.0"
description      "Installs/Configures graphite"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.6.0"

supports "ubuntu"
supports "debian"
supports "redhat"

depends  "python"
depends  "nginx"
depends  "runit"
depends  "memcached"
depends  "gunicorn"
