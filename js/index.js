import { TaskPort } from 'elm-taskport';
import packageInfo from '../package.json';

const PACKAGE_VERSION = packageInfo.version;
const PACKAGE_NAMESPACE = packageInfo.name;

/**
 * Initializes JavaScript functions for the Elm code to use.
 * 
 * @param {TaskPort} taskPort TaskPort instance to register interop functions with
 */
export function install(taskPort) {
  const ns = taskPort.createNamespace(PACKAGE_NAMESPACE, PACKAGE_VERSION);

  ns.register("localGet", (key) => window.localStorage.getItem(key));
  ns.register("localPut", (key, value) => window.localStorage.setItem(key, JSON.stringify(value)));
  ns.register("localList", (prefix) => {
    return Array(window.localStorage.length)
      .map((_, index) => window.localStorage.key(index))
      .filter((name) => name.startsWith(prefix));
  });
  ns.register("localClear", (prefix) => {
    Array(window.localStorage.length)
      .map((_, index) => window.localStorage.key(index))
      .filter((name) => name.startsWith(prefix))
      .forEach((name) => window.localStorage.removeItem(name));
  });

  ns.register("sessionGet", (key) => window.sessionStorage.getItem(key));
  ns.register("sessionPut", (key, value) => window.sessionStorage.setItem(key, JSON.stringify(value)));
  ns.register("sessionList", (prefix) => {
    return Array(window.sessionStorage.length)
      .map((_, index) => window.sessionStorage.key(index))
      .filter((name) => name.startsWith(prefix));
  });
  ns.register("sessionClear", (prefix) => {
    Array(window.sessionStorage.length)
      .map((_, index) => window.sessionStorage.key(index))
      .filter((name) => name.startsWith(prefix))
      .forEach((name) => window.sessionStorage.removeItem(name));
  });
}
