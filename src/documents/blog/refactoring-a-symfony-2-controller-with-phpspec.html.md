```
title: Refactoring a Symfony 2 Controller with PhpSpec
layout: post
date: 2013/09/04
tags: [PHP, BDD, Symfony2]
```

This is the second post in a series that looks at working with PhpSpec and Symfony 2.
In the [first post][1] we saw how it was difficult to manage (and mock) all
the dependencies that come with a controller that extends the FrameworkBundle
Controller (you can see all the [code][2] and [commits][3] for these posts on
[github][2]).

```php
namespace Peterjmit\BlogBundle\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\Controller;

class BlogController extends Controller
{
    public function indexAction()
    {
        $entityManager = $this->getDoctrine()->getManager();
        $posts = $entityManager->getRepository('PeterjmitBlogBundle:Blog')->findAll();

        return $this->render('PeterjmitBlogBundle:Blog:index.html.twig', array(
            'posts' => $posts
        ));
    }

    public function showAction($id)
    {
        $entityManager = $this->getDoctrine()->getManager();
        $post = $entityManager->getRepository('PeterjmitBlogBundle:Blog')->find($id);

        if (!$post) {
            throw $this->createNotFoundException(sprintf('Blog post %s was not found', $id));
        }

        return $this->render('PeterjmitBlogBundle:Blog:show.html.twig', array(
            'posts' => $posts
        ));
    }
}
```

## BlogController knows too much
Since the previous post, I have added `showAction` to my controller, but I have
not specced it because I know that I the mocks are going to be annoying to write,
and I can see that I have duplicated some code from `indexAction`.

This is a good indicator for the need to refactor - in both the spec, and the
controller. In order to decide how to proceed we need to identify what the
behaviour of the controller should be, versus what it currently knows.

So we know that in our controller is called during a request, and should
return a response object. We also want to show a list of, or a single blog post
(depending on the action called).

However we can see that our controller contains more behaviour than that, it knows
how to:

1. Get the templating and doctrine services from the container
2. Get a "manager" from the doctrine service
3. Get a named repository from the "manager"
4. Find blog post objects via the repository
5. Render a named template with the blog posts and return the result

Reviewing that list, only numbers 4 and 5 really seem to fall in line with
our objective, so our goal will be to remove behaviours 1-3 from our controller
<sup>1</sup>.

## Let BlogController focus on responding to a request
Having the container is convenient when we aren't writing tests, but as soon as we
start having to mock the container, our specs can get a lot less fun to write.
Therefore we are going to lose our dependency on
`Symfony\Bundle\FrameworkBundle\Controller\Controller`. To fix our failing tests
we can construct our controller with templating and doctrine instead as shown
in [this commit][4].

That commit however does not go far enough, so lets [get rid of doctrine][5] too.
We do this by introducing the repository `BlogRepository` directly, providing
the controller with the blog posts that it needs.

_edit: after some feedback I simplified the introduction of `BlogManagerInterface`
by switching it to directly injecting the repository [in this commit][16]_

```php
// ...
use Peterjmit\BlogBundle\Doctrine\BlogRepository;
use Symfony\Bundle\FrameworkBundle\Templating\EngineInterface;

class BlogController
{
    private $repository;
    private $templating;

    public function __construct(BlogRepository $repository, EngineInterface $templating)
    {
        $this->repository = $repository;
        $this->templating = $templating;
    }

    public function indexAction()
    {
        $posts = $this->repository->findAll();

        return $this->templating->renderResponse('PeterjmitBlogBundle:Blog:index.html.twig', array(
            'posts' => $posts
        ));
    }

    public function showAction($id)
    {
        $post = $this->repository->find($id);

        // ...

        return $this->templating->renderResponse('PeterjmitBlogBundle:Blog:show.html.twig', array(
            'post' => $post
        ));
    }
}
```

By now our spec is looking a lot less _difficult_ to work with, so we can introduce
[some][6] [examples][7] for `showAction`

```
// ...

class BlogControllerSpec extends ObjectBehavior
{
    function let(
        BlogRepository $repository,
        EngineInterface $templating
    ) {
        $this->beConstructedWith($repository, $templating);
    }

    function it_is_initializable()
    {
        $this->shouldHaveType('Peterjmit\BlogBundle\Controller\BlogController');
    }

    function it_should_respond_to_index_action(
        BlogRepository $repository,
        EngineInterface $templating,
        Response $mockResponse
    ) {
        $repository->findAll()->willReturn(array('An array', 'of blog', 'posts!'));

        $templating
            ->renderResponse(
                'PeterjmitBlogBundle:Blog:index.html.twig',
                array('posts' => array('An array', 'of blog', 'posts!'))
            )
            ->willReturn($mockResponse)
        ;

        $response = $this->indexAction();

        $response->shouldHaveType('Symfony\Component\HttpFoundation\Response');
    }
}
```

Check out the full [specification][8] and [controller][9] after this round of
refactoring.

The behaviour of our controller is now more tightly defined and our logic for
fetching blog posts is now re-usable in other areas of the application. While
some would argue this approach is a lot more verbose, we have gained increased
testability, code re-use and we have gone some way to decoupling our Controller
from Symfony 2.



If you hadn't already realised, in order for our controller to work within Symfony
we will have to [define it as a service][10] and this should hopefully
demonstrate some of the advantages (in terms of maintainability & testability)
of doing so.

This is not the only possible approach to making controllers within Symfony
more testable and arguably it is one of the more verbose, you can also look at
the following for removing logic from your controllers:

* [Annotations provided by SensioFrameworkExtraBundle][11]
* [Parameter converters][12]
* [Controller utility service][13]


#### See also
 * [Emergent design with PhpSpec][15]

<br>

<small>
  1. This problem is formalised by the [Law of Demeter][14] and this principal is
  very useful for identifying targets for refactoring/simplification of your code
</small>

[1]: /blog/getting-started-with-phpspec-and-symfony-2.html
[2]: https://github.com/peterjmit/getting-started-with-phpspec-and-symfony-2
[3]: https://github.com/peterjmit/getting-started-with-phpspec-and-symfony-2/commits/master
[4]: https://github.com/peterjmit/getting-started-with-phpspec-and-symfony-2/commit/3d5de3432698af520eb30c915e278d39bf53093a
[5]: https://github.com/peterjmit/getting-started-with-phpspec-and-symfony-2/commit/4a87e1d447c106e479b335a0a95c81d4feddfefa
[6]: https://github.com/peterjmit/getting-started-with-phpspec-and-symfony-2/blob/d930a806641a10706c2ed2d61219de660a8e93bb/spec/Peterjmit/BlogBundle/Controller/BlogControllerSpec.php#L47
[7]: https://github.com/peterjmit/getting-started-with-phpspec-and-symfony-2/blob/d930a806641a10706c2ed2d61219de660a8e93bb/spec/Peterjmit/BlogBundle/Controller/BlogControllerSpec.php#L65
[8]: https://github.com/peterjmit/getting-started-with-phpspec-and-symfony-2/blob/d930a806641a10706c2ed2d61219de660a8e93bb/spec/Peterjmit/BlogBundle/Controller/BlogControllerSpec.php
[9]: https://github.com/peterjmit/getting-started-with-phpspec-and-symfony-2/blob/d930a806641a10706c2ed2d61219de660a8e93bb/src/Peterjmit/BlogBundle/Controller/BlogController.php
[10]: http://symfony.com/doc/current/cookbook/controller/service.html
[11]: http://symfony.com/doc/current/bundles/SensioFrameworkExtraBundle/index.html
[12]: http://whitewashing.de/2013/02/19/extending_symfony2__paramconverter.html
[13]: http://www.whitewashing.de/2013/06/27/extending_symfony2__controller_utilities.html
[14]: http://en.wikipedia.org/wiki/Law_of_Demeter
[15]: http://www.slideshare.net/marcello.duarte/emergent-design-with-phpspec
[16]: https://github.com/peterjmit/getting-started-with-phpspec-and-symfony-2/commit/d930a806641a10706c2ed2d61219de660a8e93bb
