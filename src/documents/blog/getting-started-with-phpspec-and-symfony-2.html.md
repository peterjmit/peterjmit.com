```
title: Getting started with PhpSpec and Symfony 2
layout: post
date: 2013/08/19
tags: [PHP, BDD, Symfony2]
```

This is the first post in a series of posts that will take you through a step by
step guide to getting started with PhpSpec and Symfony 2. If you want to skip
straight to a _better_ approach for testing controllers check out my [second post][19]
in this series.

* Post 2: [Refactoring a Symfony 2 Controller with PhpSpec][19]

This first post is going to look at how a controller works within Symfony 2 and
how we might begin to start writing specifications for one (as such the following
examples should not be used in practice). Subsequent posts will refactor these
examples incorporating some techniques for better application structure.

To follow these examples you will need to install the Symfony 2 standard edition
with PhpSpec. I have created a [repository with all the example code][15] and you
can follow the commits step by step.

Lets start with a familiar example of a Controller that you may create when
you are getting started with Symfony 2 and following the examples in the
documentation.

```php
namespace Peterjmit\BlogBundle\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\Controller;

class BlogController extends Controller
{
    public function indexAction()
    {
        $repository = $this->getDoctrine()
            ->getManager()
            ->getRepository('PeterjmitBlogBundle:Blog');

        $posts = $repository->findAll();

        return $this->render(
            'PeterjmitBlogBundle:Blog:index.html.twig',
            array('posts' => $posts)
        );
    }
}
```

Using PhpSpec we can create a spec file for our `BlogController`

```bash
$ ./bin/phpspec describe Peterjmit/BlogBundle/Controller/BlogController
```

The next step is to start specifying behaviours for our controller by adding
methods to our Spec class, and as we already have an `indexAction` in
`BlogController`, we can start trying to describe the behaviour of that action.

```php
// spec/Peterjmit/BlogBundle/Controller/BlogControllerSpec.php

// ...

function it_should_respond_to_index_action()
{
    $this->indexAction();
}
```

If we try and run that spec, we will be greeted with a fatal PHP error:

> Fatal error:  Call to a member function has() on a non-object in
[...]Symfony/Bundle/FrameworkBundle/Controller/Controller.php on line 198

At this point you probably understand how to write a Symfony controller, but
exactly how it works may not be clear. To start specifying its behaviour we need
to understand how to properly isolate it, what its dependencies are, and what
behaviour it needs to fulfil as part of a Symfony 2 based application.

## What behaviour does Symfony 2 require from a controller?

This question is easy to answer, and it is one of my favourite things about
the Symfony 2 framework (suggested reading: [Requests, Controller, Response Lifecycle][2]).
Because all of the framework components are decoupled, very little happens needs
to happen within a controller, and this can make it very easy to test.

At a basic level a controller within Symfony2 is any PHP callable that returns
an instance of the [Symfony2 Response object][7]. In the standard edition a
controller is usually a method postfixed with `Action` located within a
Controller class.

Based on this information we can develop the initial spec we wrote for
`indexAction` a little further:

```php
// spec/Peterjmit/BlogBundle/Controller/BlogControllerSpec.php

// ...

function it_should_respond_to_index_action()
{
    $response = $this->indexAction();

    $response->shouldHaveType(
        'Symfony\Component\HttpFoundation\Response'
    );
}
```

The test will still fail however, because we have not yet worked out a way to
fulfil the dependencies that our `BlogController` has so that we don't get
any more fatal errors.

## Understanding the dependencies of your controller

In order to test our Controller, we need a way of fulfilling the dependencies
it has at runtime. In PhpSpec the strategy for achieving this involves isolating
the Subject Under Specification (SUS) so that our specification _only_ deals
with its behaviour.

If we revisit the controller that we created at the beginning you will see
that we have extended the [`Symfony\Bundle\FrameworkBundle\Controller\Controller`][5].
This class provides some convenience methods that let you write some common
controller actions more quickly. However from a testing point of view it means
we have a bunch of unspecified behaviours that we need to define.

### What is a `ContainerAware` controller?

To put it simply, if your controller is `ContainerAware` Symfony 2 will make
sure that the dependency injection container is available in your controller.

The framework bundle controller we have extended implements [`ContainerAwareInterface`][9]
(via the abstract class [`ContainerAware`][8]). When Symfony 2 resolves a
controller during the _Requests, Controller, Response Lifecycle_, it will call
`setContainer` with an instance of the dependency injection container
(a class implementing [`ContainerInterface`][10]) on any controller that
implements `ContainerAwareInterface`.

Therefore we need to recreate this condition in our specification and we can
do this via PhpSpec's `let` method:

```php
// spec/Peterjmit/BlogBundle/Controller/BlogControllerSpec.php

// ...

use Symfony\Component\DependencyInjection\ContainerInterface;

class BlogControllerSpec extends ObjectBehavior
{
    function let(ContainerInterface $container)
    {
        $this->setContainer($container);
    }

    // ...
```

If we try and run the specification now, we will no longer see a PHP fatal error
(yay!), instead PhpSpec will be complaining that an exception has been thrown.
This is where we can start faking, stubbing, mocking and spying on the behaviour
of the collaborators that `BlogController` relies on.

### Stubbing the interaction with Doctrine

The first method we use from the framework controller is [`getDoctrine`][11] to
get repository for our Blog entity. If you take a look at the method you will see
that it checks the container to see if the doctrine service is registered,
and returns it if it is.

In order to mock the repository (and get a list of blog posts) we need
to understand the collaborators that are involved in retrieving it from the
doctrine service, here is a list:

* `Doctrine\Common\Persistence\ManagerRegistry#getManager`
* `Doctrine\Common\Persistence\ObjectManager#getRepository`
* `Doctrine\Common\Persistence\ObjectRepository#findAll`

_(check out [the source for the interfaces][12], note if you are using custom
repository methods you will need to use that class in the spec instead of
`ObjectRepository` otherwise PhpSpec will complain)_

Just as we stubbed the container, we can stub all of these methods, and
define some more behaviour for `indexAction`:

```php
// spec/Peterjmit/BlogBundle/Controller/BlogControllerSpec.php

// ...
use Doctrine\Common\Persistence\ManagerRegistry;
use Doctrine\Common\Persistence\ObjectManager;
use Doctrine\Common\Persistence\ObjectRepository;

class BlogControllerSpec extends ObjectBehavior
{
    function let(
        ContainerInterface $container,
        ManagerRegistry $registry,
        ObjectManager $manager,
        ObjectRepository $repository
    ) {
        $container->has('doctrine')->willReturn(true);
        $container->get('doctrine')->willReturn($registry);

        $registry->getManager()->willReturn($manager);

        $manager
            ->getRepository('PeterjmitBlogBundle:Blog')
            ->willReturn($repository);

        // ...
    }

    // ...

    function it_should_respond_to_index_action(
        ObjectRepository $repository
    ) {
        // findAll could return an array of blog post entities,
        // but we are not interested in the return value of findAll
        // because it does not influence the behaviour of our
        // controller in this example
        $repository->findAll()->willReturn(array());

        $response = $this->indexAction();

        $response->shouldHaveType(
            'Symfony\Component\HttpFoundation\Response'
        );
    }
}```

At this point it is worth noting that it was somewhat of a hassle to set up all
the collaborators involved for getting a repository. When something is difficult
or _inconvenient_ to test it is an indicator that you need to look at a different
way of achieving the behaviour.

In this example our controller _knows_ too much about the implementation of
retrieving blog posts, and refactoring should aim to reduce the number of
collaborators - my next blog post will discuss how we can do this in a Symfony
application.

### Stubbing templating

The final method we use from the framework bundle controller is [`render`][13].
This method is a _proxy_ method to the `renderResponse` method on the `templating`
service which in the Symfony 2 standard edition is an instance of
[`EngineInterface`][14].

When looking at the behavour of `renderResponse` you will see that it returns
a `Response` object which will conveniently fulfil our initial specificiation
for the behaviour of `indexAction`.

The specification for mocking/stubbing templating (and the Response object)
looks like this:

```php
// spec/Peterjmit/BlogBundle/Controller/BlogControllerSpec.php

// ...
use Symfony\Bundle\FrameworkBundle\Templating\EngineInterface;
use Symfony\Component\HttpFoundation\Response;

class BlogControllerSpec extends ObjectBehavior
{
    function let(
      // ...
      EngineInterface $templating
    ) {
        // ...
        $container->get('templating')->willReturn($templating);
        // ...
    }

    // ...

    function it_should_respond_to_index_action(
        // ...
        EngineInterface $templating,
        Response $mockResponse
    ) {
        // ...
        $templating
            ->renderResponse(
                'PeterjmitBlogBundle:Blog:index.html.twig',
                array('posts' => array()),
                null
            )
            ->willReturn($mockResponse)
        ;
        // ...
    }
```

The [final code][16] for our specification can be seen in the [github repository][15]
I mentioned at the beginning. It is important to note that we didn't have to
define any routing, write any entities (or mapping) to write a valid controller.
This is part of the beauty of a BDD approach is that it allows you to focus on one
cog in the machine at a time.

## This is not the right way&trade;

As with many complex topics in education, you need to un-learn what you were
taught at the beginning to get to the next level. Hopefully you will realise is
that writing the above specifications and implementations for every controller
in your application is rather cumbersome and will create a lot of repetition
in your code base.

Advice for solving some of the problems introduced by the above examples is
outside of the scope of this initial post but we will cover it next time. Until
then here are some good resources that should begin to describe the problems and
suggest some solutions.

* [From STUPID to SOLID Code!](http://williamdurand.fr/2013/07/30/from-stupid-to-solid-code)
* [Symfony2: Controller as Service](http://richardmiller.co.uk/2011/04/15/symfony2-controller-as-service/)
* [Extending Symfony2: Controller Utilities](http://www.whitewashing.de/2013/06/27/extending_symfony2__controller_utilities.html)
* [Putting your Symfony2 controllers on a diet, part 2](http://iamproblematic.com/2012/03/12/putting-your-symfony2-controllers-on-a-diet-part-2/)

#### Some additional resources for PhpSpec

* [phpspec2: SUS and collaborators][6]
* [An explanation for fakes, stubs, mocks and spies][4]
* [A start to writing a Symfony2 extension for PhpSpec](https://github.com/phpspec/Symfony2Extension)
*****

Please get in touch with me on [twitter](https://twitter.com/peterjmit) if you
have any comments, or [fork this blog post][17] and contribute!

[1]:  http://phpspec.net/
[2]:  http://symfony.com/doc/current/book/controller.html#requests-controller-response-lifecycle
[3]:  http://symfony.com/doc/current/book/controller.html
[4]:  http://techportal.inviqa.com/2013/07/23/php-test-doubles-patterns-with-prophecy/
[5]:  https://github.com/symfony/symfony/blob/master/src/Symfony/Bundle/FrameworkBundle/Controller/Controller.php
[6]:  http://everzet.com/post/33178339051/sus-collaborators
[7]:  https://github.com/symfony/symfony/blob/master/src/Symfony/Component/HttpFoundation/Response.php
[8]:  https://github.com/symfony/symfony/blob/master/src/Symfony/Component/DependencyInjection/ContainerAware.php
[9]:  https://github.com/symfony/symfony/blob/master/src/Symfony/Component/DependencyInjection/ContainerAwareInterface.php
[10]: https://github.com/symfony/symfony/blob/master/src/Symfony/Component/DependencyInjection/ContainerInterface.php
[11]: https://github.com/symfony/symfony/blob/master/src/Symfony/Bundle/FrameworkBundle/Controller/Controller.php#L198
[12]: https://github.com/doctrine/common/tree/master/lib/Doctrine/Common/Persistence
[13]: https://github.com/symfony/symfony/blob/master/src/Symfony/Bundle/FrameworkBundle/Controller/Controller.php#L104
[14]: https://github.com/symfony/symfony/blob/master/src/Symfony/Bundle/FrameworkBundle/Templating/EngineInterface.php
[15]: https://github.com/peterjmit/getting-started-with-phpspec-and-symfony-2/commits
[16]: https://github.com/peterjmit/getting-started-with-phpspec-and-symfony-2/blob/master/spec/Peterjmit/BlogBundle/Controller/BlogControllerSpec.php
[17]: https://github.com/peterjmit/peterjmit.com/blob/master/src/documents/blog/getting-started-with-phpspec-and-symfony-2.html.md
[18]: http://www.slideshare.net/marcello.duarte/full-stack-bdd-for-symfony2
[19]: /blog/refactoring-a-symfony-2-controller-with-phpspec.html
