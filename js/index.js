import * as TaskPort from 'elm-taskport';
import packageInfo from '../package.json';

const PACKAGE_VERSION = packageInfo.version;
const PACKAGE_NAMESPACE = "lobanov/" + packageInfo.name;

/**
 * Initializes JavaScript functions for the Elm code to use.
 * 
 * @param {TaskPort} taskPort TaskPort instance to register interop functions with
 */
export function install(taskPort) {
  const ns = taskPort.createNamespace(PACKAGE_NAMESPACE, PACKAGE_VERSION);

  ns.register("localGet", (key) => window.localStorage.getItem(key));
  ns.register("localPut", ({key, value}) => window.localStorage.setItem(key, JSON.stringify(value)));
  ns.register("localRemove", (key) => window.localStorage.removeItem(key));
  ns.register("localList", () => {
    const names = Array(window.localStorage.length);
    for (let index = 0; index < names.length; index++) {
      names[index] = window.localStorage.key(index);
    }
    return names;
  });
  ns.register("localClear", () => window.localStorage.clear());

  ns.register("sessionGet", (key) => window.sessionStorage.getItem(key));
  ns.register("sessionPut", ({key, value}) => window.sessionStorage.setItem(key, JSON.stringify(value)));
  ns.register("sessionRemove", (key) => window.sessionStorage.removeItem(key));
  ns.register("sessionList", () => {
    const names = Array(window.sessionStorage.length);
    for (let index = 0; index < names.length; index++) {
      names[index] = window.sessionStorage.key(index);
    }
    return names;
  });
  ns.register("sessionClear", () => window.sessionStorage.clear());
}
