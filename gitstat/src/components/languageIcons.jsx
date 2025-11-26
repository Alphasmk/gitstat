import CSharpIcon from "../images/languages_icons/c-sharp.png";
import CIcon from "../images/languages_icons/c.png";
import CppIcon from "../images/languages_icons/cpp.png";
import CssIcon from "../images/languages_icons/css.png";
import DockerIcon from "../images/languages_icons/docker.png";
import HtmlIcon from "../images/languages_icons/html.png";
import JavaIcon from "../images/languages_icons/java.png";
import JsIcon from "../images/languages_icons/js.png";
import JsonIcon from "../images/languages_icons/json.png";
import JsxIcon from "../images/languages_icons/jsx.png";
import LessIcon from "../images/languages_icons/less.webp";
import MarkdownIcon from "../images/languages_icons/markdown.png";
import PhpIcon from "../images/languages_icons/php.png";
import PowershellIcon from "../images/languages_icons/powershell.png";
import PythonIcon from "../images/languages_icons/python.png";
import RubyIcon from "../images/languages_icons/ruby.png";
import SassIcon from "../images/languages_icons/sass.png";
import ScalaIcon from "../images/languages_icons/scala.png";
import SqlIcon from "../images/languages_icons/sql.png";
import SwiftIcon from "../images/languages_icons/swift.png";
import TsIcon from "../images/languages_icons/ts.png";
import VueIcon from "../images/languages_icons/vue.png";
import XmlIcon from "../images/languages_icons/xml.png";
import GoIcon from "../images/languages_icons/go.png";
import RustIcon from "../images/languages_icons/rust.png";
import KotlinIcon from "../images/languages_icons/kotlin.png";
import DartIcon from "../images/languages_icons/dart.png";
import LuaIcon from "../images/languages_icons/lua.png";
import PerlIcon from "../images/languages_icons/perl.png";
import RIcon from "../images/languages_icons/R.png";
import ObjCIcon from "../images/languages_icons/objc.png";
import ElixirIcon from "../images/languages_icons/elixir.webp";
import HaskellIcon from "../images/languages_icons/haskell.png";
import ReactIcon from "../images/languages_icons/react.png";
import AngularIcon from "../images/languages_icons/angular.png";
import SvelteIcon from "../images/languages_icons/svelte.png";
import NextjsIcon from "../images/languages_icons/nextjs.png";
import NuxtIcon from "../images/languages_icons/nuxt.svg";
import DjangoIcon from "../images/languages_icons/django.png";
import FlaskIcon from "../images/languages_icons/flask.webp";
import SpringIcon from "../images/languages_icons/spring.png";
import ScssIcon from "../images/languages_icons/scss.png";
import StylusIcon from "../images/languages_icons/stylus.png";
import GraphqlIcon from "../images/languages_icons/graphql.png";
import CmakeIcon from "../images/languages_icons/cmake.png";
import KubernetesIcon from "../images/languages_icons/kubernetes.png";
import TerraformIcon from "../images/languages_icons/terraform.webp";
import GitlabIcon from "../images/languages_icons/gitlab.png";
import RedisIcon from "../images/languages_icons/redis.svg";
import MongodbIcon from "../images/languages_icons/mongodb.svg";
import PostgresqlIcon from "../images/languages_icons/postgresql.png";
import MysqlIcon from "../images/languages_icons/mysql.png";
import NginxIcon from "../images/languages_icons/nginx.png";

export const languageIcons = {
    'C#': CSharpIcon,
    'C': CIcon,
    'C++': CppIcon,
    'CSS': CssIcon,
    'Dockerfile': DockerIcon,
    'HTML': HtmlIcon,
    'Java': JavaIcon,
    'JavaScript': JsIcon,
    'JSON': JsonIcon,
    'JSX': JsxIcon,
    'Less': LessIcon,
    'Markdown': MarkdownIcon,
    'PHP': PhpIcon,
    'PowerShell': PowershellIcon,
    'Python': PythonIcon,
    'Ruby': RubyIcon,
    'SCSS': SassIcon,
    'Scala': ScalaIcon,
    'SQL': SqlIcon,
    'Swift': SwiftIcon,
    'TypeScript': TsIcon,
    'Vue': VueIcon,
    'XML': XmlIcon,
    'Go': GoIcon,
    'Rust': RustIcon,
    'Kotlin': KotlinIcon,
    'Dart': DartIcon,
    'Lua': LuaIcon,
    'Perl': PerlIcon,
    'R': RIcon,
    'Objective-C': ObjCIcon,
    'Elixir': ElixirIcon,
    'Haskell': HaskellIcon,
    'React': ReactIcon,
    'Angular': AngularIcon,
    'Svelte': SvelteIcon,
    'Next.js': NextjsIcon,
    'Nuxt': NuxtIcon,
    'Django': DjangoIcon,
    'Flask': FlaskIcon,
    'Spring': SpringIcon,
    'SCSS': ScssIcon,
    'Stylus': StylusIcon,
    'GraphQL': GraphqlIcon,
    'CMake': CmakeIcon,
    'Kubernetes': KubernetesIcon,
    'Terraform': TerraformIcon,
    'GitLab': GitlabIcon,
    'Redis': RedisIcon,
    'MongoDB': MongodbIcon,
    'PostgreSQL': PostgresqlIcon,
    'MySQL': MysqlIcon,
    'Nginx': NginxIcon,
};

export const getLanguageIcon = (language) => {
  return languageIcons[language] || null;
};