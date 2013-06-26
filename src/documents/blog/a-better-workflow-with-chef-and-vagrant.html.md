```
title: A better workflow with Chef & Vagrant
layout: post
date: 2013/06/26
tags: [Chef, Vagrant, Workflow, Devops]
```

I have been using the Chef and Vagrant combo for a little under a year now and it
represented a huge improvement in time, efficiency and management of developing,
running and deploying projects. The workflow I had arrived at was not perfect
though and had a few warts that needed removing:

  1. [Getting hold of (or creating) base boxes for Vagrant](#veewee)
  2. [The chef repository can grow to be _monolithic_ and hard to understand](#simplify-chef)
  3. [Downloading and managing cookbooks outside of the Opscode repositories is difficult](#berkshelf)


#### Tools for the new workflow
You should already have VirtualBox, Chef and Vagrant installed and Configured.
You will also need to install a ruby version manager (RVM/rbenv) and the
following gems: `veewee`, `berkshelf` and `bundler` (optional). Hopefully
the following will explain the what and why being using these tools. _note that
as of writing `veewee` requires ruby 1.9.2 and `berkshelf` requires ruby 1.9.3._


<h2 id="veewee">1. Veewee to the rescue</h2>

To get a box ready to be provisioned by Vagrant, there are a few hoops to jump
through in terms of setting up software (chef, ssh, nfs, a vagrant user etc.).
This can all be set up manually, but that is not very repeatable and does not
feel very _chef-y_.

In order to find a base box to build on I used to use [www.vagrantbox.es][3] as
a starting point. Finding a correctly configured box is easier said than done,
assuming Chef is actually installed on the box, I have often found the VirtualBox
additions to be out of date which can cause problems. Not to mention I am stuck
if I cannot find a box for the OS I want to install.

Fortunately Veewee takes all the pain out of this process, with a couple of commands
you tell Veewee what OS you want to install, and fulfils all the prerequisites
necessary for Vagrant (or VMWare, KVM, Parallels for that matter). The instructions
for Veewee are well documented in the [repository][2] and in Phil Sturgeon's
[blog post][1] which originally led me to Veewee.

<h2 id="simplify-chef">2. Simplify the approach to Chef</h2>

Chef is a powerful tool and that power is provided through a few _chef-isms_.
Recipes, attributes, LWRPs, cookbooks, roles, nodes, data bags...this is not
an exhaustive list but this can steepen the learning curve both for a
beginner, or an infrequent user of Chef revisiting their installation weeks or
months later.

__The problem__

I set up my chef repository a while back, and I thought I was doing everything
as I should, I had some community cookbooks, some Github cookbooks (modified
as part of my chef-repo), and some custom cookbooks all in the same repository.
I then had roles named things like "database", "application" or "cache" and
it all seemed to fit together nicely. These roles could then be composed to build
a server to host _any_ application, theoretically keeping things separated and
re-usable.

The problem came when it was time to change the software stack slightly.
Updating cookbooks was hard to keep track of, it creates a lot of noise in the
git log (so many branches!) making debugging or rolling back changes more
difficult. My ability to understand and use the tool, and how everything fits
together was impaired - I needed Chef to capture/represent the idea of an
application and my usage was not doing that.

__The solution__

The solution almost entirely comes from a [talk by Jamie Winsor][4] of Riot
Games. Riot manage a huge persistent multiplayer gaming infrastructure using
Chef and have open sourced [a lot of their work on Github][5]. It boils down to
taking best practices that you may already be applying in software development
and applying them (which you may not be doing) to your infrastructure development.

### Abandon as many chef-isms as you can

You may be just getting started with Chef, and so we want to abandon as much of
that list of _chef-isms_ I referred to earlier to make things easier for
ourselves. The good news is that we can...forget about everything else, all we
need is a cookbook and some recipes.

### Cookbooks for applications, recipes for components

If you have done any <abbr title="Behaviour Driven Development">BDD</abbr> taking
an "outside in" approach may be familiar. I like taking this approach because
I find it makes it easier to communicate often abstract/complicated ideas and can
lead to more simplistic solutions.

In this context the "outside" is the common unit you are trying to manage with
Chef, something that everyone in the team understands - a website, application
or an API for example. In Chef we can model this basic unit of currency as a
cookbook.

The next level "in" are the components that make up an application, for a website
a basic example would be a database server and an application server. These
components are represented as recipes.

By communicating this idea/model to your team, usage of Chef/Vagrant for the team
becomes as simple as.

> To get a local environment for "my-awesome-application" up and running
> include some recipe(s) from "my-awesome-application" cookbook in your vagrant
> file.

Furthermore, fixing issues with or adding extra software packages to an
application/service becomes very clear.

> To add the "curl" package to "my-awesome-application" I can checkout
> the "my-awesome-cookbook" and add a step to the "app server" recipe

At the most simple level and if you are just getting started, most recipes will
serve as wrappers around existing cookbooks setting defaults or creating options
for software that tailored to your organisation or that are required by the
frameworks that you are using. As your understanding and requirements increase
for the tool you can start delving deeper, creating more generic and re-usable
cookbooks, Jamie's talk covers some different patterns for developing
cookbooks/recipes so if you haven't already, you should [watch it][4].

If it isn't already clear, it is important that your application cookbooks stay
isolated for them to be useful (ideally in their own version controlled
repository, separated from the Chef repository you may be used to). Cookbooks are
powerful in that Chef provides a metadata file for defining dependencies and
their versions, however the default Chef setup means that these dependencies
become part of your repository and this is not ideal, this brings me to a
solution for problem 3.

<h2 id="berkshelf">3. Put your Cookbooks on the Berkshelf</h2>

The way knife manages dependencies is unlike any other tool I use from day to
day (npm, gem, composer...). I am not a big fan of re-inventing the wheel,
or doing work a community of people have already contributed to, I have been
spoilt with the ease of which I can import 3rd party libraries in other languages
while keeping them isolated from my code base. If you want to pull in cookbooks
from Github with knife you could use the Github plugin, but that has its own
issues and hasn't seen a commit in 2 years (as of writing) and it is not free
of issues.

It is this issue that prompted me to look for a better way, and [Berkshelf][6]
seems to be the answer. Berkshelf provides the solution to writing a cookbook
in isolation, and lets you pull in 3rd party cookbooks from _any_ location
whether that be Opscode, a git repository or even your local filesystem. When you
pull in those dependencies, they stay separate from your cookbook just as with
ruby gems, or npm.

### A basic example of the workflow in action
At the beginning I provided a list of tools for the new workflow, I am going
to presuppose the following

* You are using Chef server, and have knife configured with your relevant keys
* You have set up/downloaded a box for Vagrant that is ready to provision (this example is going to be specific to Debian Wheezy)
* You have provisioned a Vagrant box via Chef server before (or know how to)
* You have the `berkshelf` gem installed and ready to use

At this point we are going to abandon the Chef repository that is described
in the official Chef documentation, and start from fresh. We are going to provision
a simple nginx webserver on Debian Wheezy using the latest version instead of
what is available in the repositories.

Create the "my-static-blog" cookbook (and get rid of the folders we aren't
going to use)

```bash
$ cd path/to/save/cookbooks
$ berks cookbook my-static-blog --license=mit
$ cd my-static-blog; rm -rf definitions files libraries providers resources templates
```

Add the Opscode nginx cookbook as a dependency in `metadata.rb`

```ruby
# metadata.rb

depends 'nginx', '>= 1.7.0'
```

As of writing the current version of nginx on Debian Wheezy is the 1.2.* branch,
because we like to stay cutting edge I want to get the 1.4.* branch and
fortunately [dotdeb][7] provides a repository for newer versions on debian. There
is an opscode community repository for dotdeb, but it doensn't support Wheezy
so we have to grab a [custom one][8]. So we add dotdeb to `metadata.rb` as before

```ruby
# metadata.rb

# Important, as this cookbook is only compatible with Debian Wheezy because of dotdeb
supports 'debian', '>= 7.0'

depends 'nginx',  '>= 1.7.0'
depends 'dotdeb', '>= 0.1.2'
```

To grab the dotdeb cookbook from Github we need to add a line to `Berksfile`,
`site :opscode` and `metadata` should already be there, this tells Berkshelf
to resolve dependencies in `metadata.rb` from the Opscode repositories by default

```
# Berksfile

site :opscode

metadata

cookbook "dotdeb", github: "peterjmit/chef-dotdeb"
```

Next you can create a recipe for the web server to tie this all together and
configure nginx

```ruby
# recipes/web_server.rb

# You configure some the nginx attributes in the recipe
# for example, turning gzip off
node.set[:nginx][:gzip] = 'off'

# Include the default recipes to get nginx installed via dotdeb
include_recipe 'dotdeb'
include_recipe 'nginx'
```

If suitable for your application, you can add your components
to `recipes/default.rb` to allow installation of the full application via

```ruby
# recipes/default.rb

include_recipe 'my-static-blog::web_server'
```

Now you are ready to roll, if you run `berks install` you will install
the cookbooks you have specified (and their dependencies) to
`~/.berkshelf/cookbooks/`. To get your cookbooks on the chef server use
`berks upload`. Once you have have done that you are ready to provision
your Vagrant box, it is as simple as:

```ruby
# Vagrantfile

config.vm.provision :chef_client do |chef|
  # chef server config

  chef.add_recipe 'my-static-blog'
end
```

With any luck you will be able to run `vagrant up` and voilà, your nginx webserver
has been provisioned. Most applications are a bit more complex than that, but
by adding a scripting language recipe to `web_server` recipe and perhaps
introducing a `database_server` recipe you can see how you can build on your
application cookbooks.

#### Added bonus

There are a few different ways of doing things in Chef, and things change from
version to version, fortunately there is a gem called `foodcritic` that will lint
your cookbooks for you and report errors, deprecated syntax etc. I highly
recommend installing it to catch any errors before trying to provision your
cookbooks.

Please [give me a shout on twitter](https://twitter.com/peterjmit) if you have
any comments, contributions or corrections for this blog post, all constructive
feedback is welcome.

_Many thanks to Riot Games, Jamie Winsor, and Opscode for open sourcing great
tools and making high quality learning materials available online_

[1]: http://philsturgeon.co.uk/blog/2013/05/build-your-own-vagrant-boxes-with-veewee
[2]: https://github.com/jedi4ever/veewee
[3]: http://www.vagrantbox.es/
[4]: http://www.youtube.com/watch?v=hYt0E84kYUI
[5]: https://github.com/riotgames
[6]: http://berkshelf.com/
[7]: http://www.dotdeb.org/
[8]: https://github.com/peterjmit/chef-dotdeb
