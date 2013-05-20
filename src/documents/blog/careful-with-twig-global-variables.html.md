```
title: Be careful with global variables in Symfony 2 Twig extensions
layout: post
date: 2013-05-20
tags: [PHP, Symfony2, Twig]
```

I stumbled across a confusing error message while developing some new
functionality in one of my Symfony 2 based applications.

I was using some Behat scenarios to guide me through a payment listener that
emails a customer when their payment has been confirmed. Everything was working
fine until I tried to introduce a Twig template as the body of an email.

> [Symfony\Component\DependencyInjection\Exception\InactiveScopeException]
> You cannot create a service ("request") of an inactive scope ("request").

Initially I was stumped, the error message did not point me directly
to any code I was working with, nor anything I had recently looked at.

After a lot of head scratching I remembered a Twig extension that I had
written over a year ago. It helps to conditionally execute javascript
based on the users current location within the application (inspired by
Paul Irish's [blog post][1]).

```php
// ../Twig/Extension/MyExtension.php
public function getRouteInfo()
{
    $request = $this->container->get('request');
    $route = $request->attributes->get('_route');

    // ...

    return $routeInfo;
}
```

In order to make `$routeInfo` available to all my templates, I had decided
to make it to global.

```php
// ../Twig/Extension/MyExtension.php
public function getGlobals()
{
    return ['route' => $this->getRouteInfo()];
}
```

The problem with this is that I have given my Twig environment a hard dependency
on the `Request` object. Every time I try and use Twig, it will make that `getGlobals`
call, which in turn will be trying to access the `Request` object.

This is why, in the CLI context where there is no `Request` object I was seeing
the inactive scope exception. While I would not necessarily take the above approach
again, the fix is quite easy &mdash; the Symfony 2 container provides a method
for checking if a scope is active or not, which means I can rewrite my
`getRouteInfo` method:

```php
// ../Twig/Extension/MyExtension.php
public function getRouteInfo()
{
    if (!$this->container->isScopeActive('request')) {
        return null;
    }

    $request = $this->container->get('request');
    $route = $request->attributes->get('_route');

    // ...

    return $routeInfo;
}
```

I generally try and shy away from making variables global (in any context) and
this example reinforces my wariness of using `getGlobals` in Twig extensions.



[1]: http://paulirish.com/2009/markup-based-unobtrusive-comprehensive-dom-ready-execution/
