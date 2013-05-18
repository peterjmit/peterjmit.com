```
title: Why should you upgrade your test suite to PhpSpec & Prophecy
layout: post
date: 2013-05-06
tags: [php, bdd]
```

PhpSpec has recently dropped a 2.0 beta, and it has moved from the mock object
framework "Mockery" in favour of a new framework called
[Prophecy](https://github.com/phpspec/prophecy).

#### The tl;dr guide to upgrading your test suite
1. Add `"phpspec/phpspec": "2.0.*@dev"` to `composer.json`
2. Change all instances of the `PHPSpec2` namespace to `PhpSpec`
3. Rename all your `spec/<MyClass>` specs to `spec/<MyClass>Spec`
4. Replace the `ANY_ARGUMENT` constant with `Prophecy\Argument::any()`

Having done the above, your test suite should run but you may see some new failures due to the way Prophecy works

1. [PhpSpec will not let you use methods that are undefined on collaborators](#undefined-methods)
2. [Any method called during a spec has to be stubbed](#stub-methods)

<hr>

Documentation is a bit sparse on the ground (but you can [contribute](https://github.com/phpspec/phpspec)) so hopefully I can give you a couple of pointers for upgrading your test suite. I have created an [example repository][1] to try and give a quick guide through some of the updates and differences between PhpSpec/Mockery & PhpSpec/Prophecy.

## First step &ndash; update/install PhpSpec with Prophecy

I am assuming you are using composer you can get a fresh copy of PhpSpec by adding
or editing the following dependency in `composer.json`

```json
"phpspec/phpspec": "2.0.*@dev"
```

## Changes that will _break_ your spec files
At first glance not much has changed, hit the following command and it appears
to be business as usual. But if you are trying to run an _old_ test suite
then nothing will work.

```bash
$ ./vendor/bin/phpspec desc HelloWorld
```

Take a look at the [generated spec][2] and you will notice a couple of
changes.

### PhpSpec has a new namespace

The namespace `PHPSpec2` has changed to `PhpSpec`, for example many of your specs will will extend `PHPSpec2\ObjectBehavior`, so you will want to update your use statement to `use PhpSpec\ObjectBehavior;`.

### Spec files/classes now have the suffix "Spec"

If you are upgrading existing specs, you will need to rename your spec for `HelloWorld.php` to `HelloWorldSpec.php`.

### The ANY_ARGUMENT(S) constant has gone

In some of your mock expectations, you may have used something like

```php
$mockObject->methodStub(ANY_ARGUMENT);
```

Prophecy handles [arguments wildcarding][3] slightly differently. If you take a
look at our initial spec again you will see that `phpspec desc` generates a spec with a use statement for `Prophecy\Argument`. If you want a direct replacement for `ANY_ARGUMENT` then you should use:

```php
$mockObject->methodStub(Prophecy\Argument::any());
```

## Changes that can make your specs _better_

Prophecy integration with PhpSpec contains two key features that give me a lot
more confidence in my specs and they may cause your existing test suite to fail.

<h3 id="undefined-methods">PhpSpec complains about un-defined methods in collaborators</h3>

If you take a look at [this commit][4] I have tried to specify that `HelloWorld`
will say hello to a `Person`. With previous versions of PhpSpec this would have worked
however Prophecy will complain:

![Undefined method screenshot](https://raw.github.com/peterjmit/phpspec-prophecy-example/master/screenshots/undefined-method.png)

This is a useful change, for example:

  1. If you refactor a method name, but don't update a dependant class - it will be caught by the test suite
  2. If you type hint for an interface, but use methods not defined within that interface your test will fail

<h3 id="stub-methods">Stubs in PhpSpec/Prophecy are "all or nothing"</h3>

In Mockery, if you call a method that has not been explictly stubbed it would
return an instance of `Mockery\Undefined`. This is problematic, because if you
use loose comparisons, your test suite may behave unexpectedly. If you consider
the following block of code that was added in [this commit][5]

```javascript
// ...
if ($person->isMale()) {
    $salutation = 'Mr. ';
} else if ($person->isFemale()) {
    $salutation = 'Ms. ';
} else {
    // gender in-specific salutation
    $salutation = '';
}
// ...
```

In the spec, we stub `$person->isFemale()` and `$person->getName()`

```php
// test name shortened for brevity
function it_should_address_/*..*/($person)
{
    $person->getName()->willReturn('Jane');
    $person->isFemale()->willReturn(true);

    $this->addressSomeoneWithSalutation($person)
        ->shouldReturn('Dear Ms. Jane');
}
```

If you haven't realised yet with Mockery this spec will always fail, but not in
an expected way (or a way that would occur in an actual runtime). The call
to `$person->isMale()` will always evaluate to true (because the object `Mockery\Undefined`
is returned and coerced to `true`), incorrectly giving us the salutation for a male.

Prophecy on the other hand will not put up with this, failing the test with a
useful message.

[edit] This is because stubs in Prophecy are "loose demand doubles", if you do not stub
any methods on them, they will always return `null`. Once you stub a method they
become "strict demand doubles" requiring you to stub all methods that your
<abbr title="Subject Under Specification">SUS</abbr> is interacting with. <sup>[1](#ref-1)</sup>

![Method not stubbed](https://raw.github.com/peterjmit/phpspec-prophecy-example/master/screenshots/method-not-stubbed.png)

We are therefore forced to stub `$person->isMale()` in order for our tests to pass
 as shown in [this commit][6].

If you have a comment on this post, or if I have missed any of the standout
new features then let me know [on twitter](https://twitter.com/peterjmit) or
<a href="mailto:pete@peterjmit.com?subject=Re: Why should you upgrade your test suite to PhpSpec & Prophecy">email me</a>

<small id="ref-1">\[1\] thanks to [@everzet](https://twitter.com/everzet) & [@_md](https://twitter.com/_md) for providing explanation on twitter</small>


[1]: https://github.com/peterjmit/phpspec-prophecy-example "PhpSpec & Prophecy example repo"
[2]: https://github.com/peterjmit/phpspec-prophecy-example/commit/f2cfc57dd99b14226a417863785eaf6b660fc651 "HelloWorld spec description"
[3]: https://github.com/phpspec/prophecy#arguments-wildcarding "PhpSpec docs - Arguments Wildcarding"
[4]: https://github.com/peterjmit/phpspec-prophecy-example/commit/08d5ba9098afd090f56632a45429047e9843e7c8 "Commit with undefined method on collaborator"
[5]: https://github.com/peterjmit/phpspec-prophecy-example/commit/d03dd5aae4dfb4611ff04c4f35664cfd67d82704 "Example of calling a method that hasn't been stubbed"
[6]: https://github.com/peterjmit/phpspec-prophecy-example/commit/1038519d8985dd095d92cb87d35e605caa728a13 "Commit resolving un-stubbed method issue"
