elm-localstorage
================

An Elm package providing access to browser's `window.localStorage` and `window.sessionStorage` to Elm code using Task API. The same repository contains the source for the Elm package, as well as the source for the JavaScript NPM companion package.

This package works in Chrome, Firefox, and Safari.

In addition to being useful on its own, this package is also providing an example on how to wrap any JavaScript API into an Elm Task using [elm-taskport](https://package.elm-lang.org/packages/lobanov/elm-taskport/latest/) package. It uses TaskPort's function namespaces to avoid name clashes with other JS interop functions, as well as to benefit from out-of-the-box support for ensuring JS and Elm code are in sync.

Installation
------------

This package contains Elm code that requires setup on the JavaScript side. It also uses `elm-taskport` package for Task-based JavaScript interop. A few installation steps are required before this package can be used.

### 1. Add elm-localstorage to your Elm application

The Elm package is installed in a traditional way.

```sh
elm install elm-localstorage
```

Take a note of the versions of `elm-localstorage` and `elm-taskport` packages that got pulled from the Elm package registry. They will be required in the next step.

Note that this package should work with any version of `elm-taskport` above 2.0.0, so if your application requires `elm-taskport` of an earlier version, feel free to not use the latest one.

### 1. Add JavaScript companion code to your application

There are two ways to go about doing this depending on what is more appropriate for your application.

For Elm applications that don't have much of HTML/JavaScript code, JavaScript code for `elm-taskport` and `elm-localstorage` packages can be included using a `<script>` tag.

```html
<script src="https://unpkg.com/elm-taskport@TASKPORT_PACKAGE_VERSION/dist/taskport.min.js"></script>
<script src="https://unpkg.com/elm-localstorage@LOCALSTORAGE_PACKAGE_VERSION/dist/localstorage.min.js"></script>
```

Substitute the version of `elm-taskport` package instead of `TASKPORT_PACKAGE_VERSION` the version of the `elm-localstorage` package instead of `LOCALSTORAGE_PACKAGE_VERSION`. The code is checking that Elm and JS are on the same version to prevent things blowing up. If dependency on [unpkg CDN](https://unpkg.com) makes your nervous, you can choose to distribute the JS files with the rest of your application. In this case, simply save them locally, add to your codebase, and modify the path in the `<script>` tag accordingly.

For Elm applications which use a bundler like Webpack, JavaScript code for the package can be downloaded via NPM.

```sh
npm add --save elm-localstorage # or yarn add elm-localstorage --save
```

This will bring all necessary JavaScript files files into `node_modules` directory. Once that is done, you can include the JavaScript code for `elm-localstorage` and `elm-taskport` in your main JavaScript (`app.js`) or TypeScript (`app.ts`) file.

```js
import * as TaskPort from 'elm-taskport';
import * as LocalStorage from 'elm-localstorage';
// use the following lines instead of using a CommonJS target
// const TaskPort = require('elm-taskport');
// const LocalStorage = require('elm-localstorage');
```

### 2. Install TaskPort and LocalStorage

Add a script block to your HTML file to enable TaskPort in your environment and then register JavaScript interop functions required for this packge.

```html
<script>
    TaskPort.install();
    LocalStorage.install(TaskPort);

    // it may be the same script block where you initialise your Elm application 
</script>
```

Check out `elm-taskport` package documentation for details on configuring TaskPort, but default settings should work in most cases.

Usage
-----

### Overview

This package uses taskports under the hood. Taskports are a JavaScript interop mechanism introduced by [elm-taskport](https://package.elm-lang.org/packages/lobanov/elm-taskport/latest/) package, which allow to wrap call of any JavaScript code into a [Task](https://package.elm-lang.org/packages/elm/core/latest/Task#Task), which is Elm's abstraction for an effectful operation. Tasks can be chained together to achieve complex side effects, such as making multiple API calls, interacting with the runtime environment, etc.

This package provides `LocalStorage` Elm module, that contains functions creating Tasks representing operations with `window.localStorage` and `window.sessionStorage` objects. The module does not provide a mechanism to hand these tasks over to the Elm runtime for execution. Instead, the developers are expected to do that in their `init` or `update` function by the means of invoking `Task.attempt` to create `Cmd` values. If this does not make sense, make sure you are familiar with the principles of the effectful [Elm Architecture](https://guide.elm-lang.org/effects/) and the API of the Elm's [Task module](https://package.elm-lang.org/packages/elm/core/latest/Task).

The API of `LocalStorage` module follows the standard operations available in `window.localStorage` and `window.sessionStorage` objects in modern browsers. In the Web Platform `window.localStorage` provides a key-value API used for storing any information on user's device, which is persisted between browsing sessions. On contrary, `window.sessionStorage` persists information only whilst the current browsing tab is open. The API is identical between the two, only the retention logic is different.

The following table summarises the functions available in `LocalStorage` module and their Web Platform counterparts.

* `window.localStorage.putItem(key, value): void`
    + `LocalStorage.localPut`
* `window.localStorage.getItem(key): string | undefined`
    + `LocalStorage.localGet`
* `window.localStorage.removeItem(key): void`
    + `LocalStorage.localRemove`
* `window.localStorage.key(index): string` (where index = 0 .. `window.localStorage.length`)
    + `LocalStorage.localListkeys`
* `window.localStorage.clear(): void`
    + `LocalStorage.localClear`
* `window.sessionStorage.putItem(key, value): void`
    + `LocalStorage.sessionPut`
* `window.sessionStorage.getItem(key): string | undefined`
    + `LocalStorage.sessionGet`
* `window.sessionStorage.removeItem(key): void`
    + `LocalStorage.sessionRemove`
* `window.sessionStorage.key(index): string` (where index = 0 .. `window.sessionStorage.length`)
    + `LocalStorage.sessionListkeys`
* `window.sessionStorage.clear(): void`
    + `LocalStorage.sessionClear`

### Basic examples

The below examples demonstrate how to use `LocalStorage.localXXX` functions. The same would apply to their `LocalStorage.sessionXXX` counterparts.

Set value for a key:

```elm
type Msg = OK (Result TaskPort.Error ())
LocalStorage.localPut "key" "value" |> Task.attempt OK
```

Get value for a key:

```elm
type Msg = GotValue (Result TaskPort.Error (Maybe String)) -- note that if there is no value, the result will be Result.Ok Nothing
LocalStorage.localGet "key" |> Task.attempt GotValue
```

List keys:

```elm
type Msg = GotKeys (Result TaskPort.Error (List String))
LocalStorage.localListKeys |> Task.attempt GotKeys
```

Remove value for a key:

```elm
type Msg = OK (Result TaskPort.Error ())
LocalStorage.localRemove "key" |> Task.attempt OK
```

### Advanced examples

Benefits of using Task API are the most apparent when you need to perform several effectful operations one after another.

#### Removing all keys with a given prefix

```elm
removeWithPrefix : String -> TaskPort.Task ()
removeWithPrefix prefix = 
    LocalStorage.localListKeys -- produces a Task Error (List String)
        |> Task.andThen -- : List String -> Task Error ()
            (\keys -> keys
                |> List.filter (String.startsWith prefix)
                |> List.map LocalStorage.localRemove
                |> Task.sequence -- takes List (Task Error ()) and executes as a sequence of tasks wrapping all in Task Error (List ())
            )
        |> Task.map \_ -> () -- only to avoid the weird function type, othertise it'll be TaskPort.Task (List ())
```

#### Store and retrieve JSON values in local storage

```elm
import Json.Encode as JE
import Json.Decode as JD
import TaskPort
import LocalStorage

putJson : Key -> JE.Value -> Task ()
putJson key jsonValue = LocalStorage.localPut key (JE.encode 0 jsonValue)

-- custom type combining TaskPort errors and Json decoding errors
-- because the Task can only have one error type
type JsonError 
    = InteropCallFailed TaskPort.Error
    | MalformedJson JD.Error

getJson : Key -> Task JsonError JE.Value
getJson key = LocalStorage.localGet key
    |> Task.andThen
        (\stringValue -> 
            case (JD.decodeString JD.value) of -- JD.decodeString produces a Result
                Result.Ok jsonValue -> Task.succeed jsonValue
                Result.Err decodeError -> Task.fail (MalformedJson decodeError)
        )
```

#### Combining different Tasks

In the following example application's `init` function attempts to retrieve the model from the session storage to recover from a page refresh, but if nothing is returned, it makes an HTTP call to the backend to initialize the model. The `update` function synchronises the session storage with the model of the application on every change.

```elm
import Json.Encode as JE
import Json.Decode as JD
import TaskPort
import LocalStorage
import Http

type alias Config = { {- ... complex type ... -} }
type alias Model = Maybe Config
type InitError = InteropError TaskPort.Error | HttpError Http.Error
type Msg = Initialized (Result InitError Config) | ConfigChange {- ... parameters ... -} | Updated ()

configDecoder : JD.Decoder Config
configDecoder = {- ... decoder implementation ... -}

configEncoder : Config -> JE.Value
configEncoder config = {- ... encoder implementation -}

init : () -> ( Model, Cmd )
init _ =
    ( Nothing, -- no value initially
    , LocalStorage.sessionGet "model"
        |> Task.onError InteropError -- force conformance to the single error type of InitError
        |> Task.andThen
            (\maybeConfigString -> maybeConfigString
                -- if unable to decode JSON (e.g. format has changed), just fall back to the HTTP call
                |> Maybe.andThen (\configString -> Result.toMaybe (JD.decodeString configDecoder configString)) 
                |> Maybe.andThen Task.succeed
                |> Maybe.withDefault
                ( Http.task { {- ... configure http call using configDecoder, omitted for brevity ... -} }
                    |> Task.onError HttpError -- force conformance to the single error type of InitError
                )
            )
        |> Task.attempt Initialized -- pass the task to the Elm runtime
    )

update : Msg -> Model -> ( Model, Cmd )
update msg maybeModel =
    case ( maybeModel, msg ) of
        ( Nothing, Initialized (Result.Ok config) ) -> ( Just config, Cmd.none )
        ( Just config, ConfigChange {- ... parameters ... -} ) -> 
            ( Just {- ... updated config ... -}
            , configEncoder config -- synchronizing browser's session storage on any config change
                |> JE.encode 0 
                |> LocalStorage.sessionPut "model"
                |> Task.onError (\_ -> Task.succeed ())
                |> Task.perform Updated -- we choose to ignore errors
            )
        
        -- for the sake of example, we are ignoring other combinations, such as:
        -- ( Just mode, Updated ) when session storage is synchronised with the model update
        -- ( Nothing, Initialized (Result.Err error) ) something went wrong
        -- a robust application will handle those in a meaningful way even if only to show an error to the user
        _ -> ( maybeModel, Cmd.none )
```

Getting support
---------------

For questions or general enquiries feel free to tag or DM `@lobanov` on [Elm Slack](https://elmlang.slack.com/).

For issues or suggestions please raise an issue on GitHub.

PRs are welcome.
