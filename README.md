elm-localstorage
================

An Elm package providing access to browser's `window.localStorage` and `window.sessionStorage` to Elm code using Task API. The same repository contains the source for the Elm package, as well as the source for the JavaScript NPM companion package.

This package works in Chrome, Firefox, and Safari.

In addition to being useful on its own, this package is also providing an example on how to wrap any JavaScript API into an Elm Task using [elm-taskport](https://package.elm-lang.org/packages/lobanov/elm-taskport/latest/) package. It uses TaskPort's function namespaces to avoid name clashes with other JS interop functions, as well as to benefit from out-of-the-box support for ensuring JS and Elm code are in sync.

Installation
------------

This package contains Elm code that requires setup on the JavaScript side. There are a few steps that need to be done.

### 1. Include JavaScript companion code
There are two ways to go about doing this depending on what is more appropriate for your application.

For Elm applications that don't have much of HTML/JavaScript code, TaskPort and elm-localstorage can be included using a `<script>` tag.

```html
<script src="https://unpkg.com/elm-taskport@2.0.0/dist/taskport.min.js"></script>
<script src="https://unpkg.com/elm-localstorage@ELM_PACKAGE_VERSION/dist/localstorage.min.js"></script>
```

Substitute the actual version of the `elm-localstorage` package instead of `ELM_PACKAGE_VERSION`. The code is checking that Elm and JS are on the same version to prevent things blowing up. If dependency on [unpkg CDN](https://unpkg.com) makes your nervous, you can choose to distribute the JS files with the rest of your application. In this case, simply save them locally, add to your codebase, and modify the path in the `<script>` tag accordingly.

For Elm applications which use a bundler like Webpack, JavaScript code for the package can be downloaded via NPM.

```sh
npm add --save elm-localstorage # or yarn add elm-localstorage --save
```

This will bring all necessary JavaScript files files into `node_modules/elm-localstorage` directory, as well as . Once that is done, you can include TaskPort and LocalStorage in your main JavaScript or TypeScript file.

```js
import * as TaskPort from 'elm-taskport';
import * as LocalStorage from 'elm-localstorage';
// use the following lines instead of using a CommonJS target
// const TaskPort = require('elm-taskport');
// const LocalStorage = require('elm-localstorage');
```

### 2. Install TaskPort and LocalStorage

For browser-based Elm applications add a script to your HTML file to enable TaskPort in your environment and then register JavaScript interop functions required for this packge.

```html
<script>
    TaskPort.install();
    LocalStorage.install(TaskPort);

    // it may be the same script block where you initialise your Elm application 
</script>
```

Usage
-----

This package uses taskports under the hood. Taskports are a JavaScript interop mechanism introduced by [elm-taskport](https://package.elm-lang.org/packages/lobanov/elm-taskport/latest/) package, which allow to wrap call of any JavaScript code into a [Task](https://package.elm-lang.org/packages/elm/core/latest/Task#Task), which is Elm's abstraction for an effectful operation. Tasks can be chained together to achieve complex side effects, such as making multiple API calls, interacting with the runtime environment, etc.

## Basic usage

LocalStorage module's interface closely follows standard operations available in `window.localStorage` and `window.sessionStorage` objects.
In the Web Platform `window.localStorage` provides a key-value API used for storing any information on user's device, which is persisted between browsing sessions. On contrary, `window.sessionStorage` persists information only whilst the current browsing tab is open. The API is identical between the two, only the retention policy is different.

operation | `window.localStorage` | `window.sessionStorage`
---|---|---
set value for a key | `LocalStorage.localPut` | `LocalStorage.sessionPut`
get value for a key | `LocalStorage.localGet` | `LocalStorage.sessionGet`
remove value for a given key | `LocalStorage.localRemove` | `LocalStorage.sessionRemove`
list all keys | `LocalStorage.localListKeys` | `LocalStorage.sessionListKeys`
remove all values | `LocalStorage.localClear` | `LocalStorage.sessionClear`

Set value for a key:

```elm
LocalStorage.localPut "key" "value" |> Task.attempt
```

## Advanced usage

Benefits of using Task API are the most apparent when you need to perform several effectful operations one after another.

### Removing all keys with a given prefix

```elm
removeWithPrefix : String -> TaskPort.Task ()
removeWithPrefix prefix = 
    LocalStorage.localListKeys
        |> Task.andThen (\keys ->
            keys
                |> List.filter (String.startsWith prefix)
                |> List.map LocalStorage.localRemove
                |> Task.sequence
        )
        |> Task.map \_ -> ()
```
