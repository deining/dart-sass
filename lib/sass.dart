// Copyright 2016 Google Inc. Use of this source code is governed by an
// MIT-style license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

/// We strongly recommend importing this library with the prefix `sass`.
library sass;

import 'package:package_config/package_config_types.dart';
import 'package:source_maps/source_maps.dart';

import 'src/async_import_cache.dart';
import 'src/callable.dart';
import 'src/compile.dart' as c;
import 'src/compile_result.dart';
import 'src/exception.dart';
import 'src/import_cache.dart';
import 'src/importer.dart';
import 'src/logger.dart';
import 'src/syntax.dart';
import 'src/util/nullable.dart';
import 'src/visitor/serialize.dart';

export 'src/callable.dart' show Callable, AsyncCallable;
export 'src/compile_result.dart';
export 'src/exception.dart' show SassException;
export 'src/importer.dart';
export 'src/logger.dart';
export 'src/syntax.dart';
export 'src/value.dart' hide SassApiColor;
export 'src/visitor/serialize.dart' show OutputStyle;
export 'src/warn.dart' show warn;

/// Loads the Sass file at [path], compiles it to CSS, and returns a
/// [CompileResult] containing the CSS and additional metadata about the
/// compilation.
///
/// If [color] is `true`, this will use terminal colors in warnings. It's
/// ignored if [logger] is passed.
///
/// If [logger] is passed, it's used to emit all messages that are generated by
/// Sass code. Users may pass custom subclasses of [Logger].
///
/// Imports are resolved by trying, in order:
///
/// * Loading a file relative to [path].
///
/// * Each importer in [importers].
///
/// * Each load path in [loadPaths]. Note that this is a shorthand for adding
///   [FilesystemImporter]s to [importers].
///
/// * Each load path specified in the `SASS_PATH` environment variable, which
///   should be semicolon-separated on Windows and colon-separated elsewhere.
///
/// * `package:` resolution using [packageConfig], which is a
///   [`PackageConfig`][] from the `package_resolver` package. Note that
///   this is a shorthand for adding a [PackageImporter] to [importers].
///
/// [`PackageConfig`]: https://pub.dev/documentation/package_config/latest/package_config.package_config/PackageConfig-class.html
///
/// Dart functions that can be called from Sass may be passed using [functions].
/// Each [Callable] defines a top-level function that will be invoked when the
/// given name is called from Sass.
///
/// The [style] parameter controls the style of the resulting CSS.
///
/// If [quietDeps] is `true`, this will silence compiler warnings emitted for
/// stylesheets loaded through [importers], [loadPaths], or [packageConfig].
///
/// By default, once a deprecation warning for a given feature is printed five
/// times, further warnings for that feature are silenced. If [verbose] is true,
/// all deprecation warnings are printed instead.
///
/// If [sourceMap] is `true`, [CompileResult.sourceMap] will be set to a
/// [SingleMapping] that indicates which sections of the source file(s)
/// correspond to which in the resulting CSS. [SingleMapping.targetUrl] will be
/// `null`. It's up to the caller to save this mapping to disk and add a source
/// map comment to [CompileResult.css] pointing to it. Users using the
/// [SingleMapping] API should be sure to add the [`source_maps`][] package to
/// their pubspec.
///
/// [`source_maps`]: https://pub.dartlang.org/packages/source_maps
///
/// If [charset] is `true`, this will include a `@charset` declaration or a
/// UTF-8 [byte-order mark][] if the stylesheet contains any non-ASCII
/// characters. Otherwise, it will never include a `@charset` declaration or a
/// byte-order mark.
///
/// [byte-order mark]: https://en.wikipedia.org/wiki/Byte_order_mark#UTF-8
///
/// Throws a [SassException] if conversion fails.
///
/// {@category Compile}
CompileResult compileToResult(String path,
        {bool color = false,
        Logger? logger,
        Iterable<Importer>? importers,
        Iterable<String>? loadPaths,
        PackageConfig? packageConfig,
        Iterable<Callable>? functions,
        OutputStyle? style,
        bool quietDeps = false,
        bool verbose = false,
        bool sourceMap = false,
        bool charset = true}) =>
    c.compile(path,
        logger: logger,
        importCache: ImportCache(
            importers: importers,
            logger: logger ?? Logger.stderr(color: color),
            loadPaths: loadPaths,
            packageConfig: packageConfig),
        functions: functions,
        style: style,
        quietDeps: quietDeps,
        verbose: verbose,
        sourceMap: sourceMap,
        charset: charset);

/// Compiles [source] to CSS and returns a [CompileResult] containing the CSS
/// and additional metadata about the compilation..
///
/// This parses the stylesheet as [syntax], which defaults to [Syntax.scss].
///
/// If [color] is `true`, this will use terminal colors in warnings. It's
/// ignored if [logger] is passed.
///
/// If [logger] is passed, it's used to emit all messages that are generated by
/// Sass code. Users may pass custom subclasses of [Logger].
///
/// Imports are resolved by trying, in order:
///
/// * The given [importer], with the imported URL resolved relative to [url].
///
/// * Each importer in [importers].
///
/// * Each load path in [loadPaths]. Note that this is a shorthand for adding
///   [FilesystemImporter]s to [importers].
///
/// * Each load path specified in the `SASS_PATH` environment variable, which
///   should be semicolon-separated on Windows and colon-separated elsewhere.
///
/// * `package:` resolution using [packageConfig], which is a
///   [`PackageConfig`][] from the `package_resolver` package. Note that
///   this is a shorthand for adding a [PackageImporter] to [importers].
///
/// [`PackageConfig`]: https://pub.dev/documentation/package_config/latest/package_config.package_config/PackageConfig-class.html
///
/// Dart functions that can be called from Sass may be passed using [functions].
/// Each [Callable] defines a top-level function that will be invoked when the
/// given name is called from Sass.
///
/// The [style] parameter controls the style of the resulting CSS.
///
/// The [url] indicates the location from which [source] was loaded. It may be a
/// [String] or a [Uri]. If [importer] is passed, [url] must be passed as well
/// and `importer.load(url)` should return `source`.
///
/// If [quietDeps] is `true`, this will silence compiler warnings emitted for
/// stylesheets loaded through [importers], [loadPaths], or [packageConfig].
///
/// By default, once a deprecation warning for a given feature is printed five
/// times, further warnings for that feature are silenced. If [verbose] is true,
/// all deprecation warnings are printed instead.
///
/// If [sourceMap] is `true`, [CompileResult.sourceMap] will be set to a
/// [SingleMapping] that indicates which sections of the source file(s)
/// correspond to which in the resulting CSS. [SingleMapping.targetUrl] will be
/// `null`. It's up to the caller to save this mapping to disk and add a source
/// map comment to [CompileResult.css] pointing to it. Users using the
/// [SingleMapping] API should be sure to add the [`source_maps`][] package to
/// their pubspec.
///
/// [`source_maps`]: https://pub.dartlang.org/packages/source_maps
///
/// If [charset] is `true`, this will include a `@charset` declaration or a
/// UTF-8 [byte-order mark][] if the stylesheet contains any non-ASCII
/// characters. Otherwise, it will never include a `@charset` declaration or a
/// byte-order mark.
///
/// [byte-order mark]: https://en.wikipedia.org/wiki/Byte_order_mark#UTF-8
///
/// Throws a [SassException] if conversion fails.
///
/// {@category Compile}
CompileResult compileStringToResult(String source,
        {Syntax? syntax,
        bool color = false,
        Logger? logger,
        Iterable<Importer>? importers,
        PackageConfig? packageConfig,
        Iterable<String>? loadPaths,
        Iterable<Callable>? functions,
        OutputStyle? style,
        Importer? importer,
        Object? url,
        bool quietDeps = false,
        bool verbose = false,
        bool sourceMap = false,
        bool charset = true}) =>
    c.compileString(source,
        syntax: syntax,
        logger: logger,
        importCache: ImportCache(
            importers: importers,
            logger: logger ?? Logger.stderr(color: color),
            packageConfig: packageConfig,
            loadPaths: loadPaths),
        functions: functions,
        style: style,
        importer: importer,
        url: url,
        quietDeps: quietDeps,
        verbose: verbose,
        sourceMap: sourceMap,
        charset: charset);

/// Like [compileToResult], except it runs asynchronously.
///
/// Running asynchronously allows this to take [AsyncImporter]s rather than
/// synchronous [Importer]s. However, running asynchronously is also somewhat
/// slower, so [compileToResult] should be preferred if possible.
Future<CompileResult> compileToResultAsync(String path,
        {bool color = false,
        Logger? logger,
        Iterable<AsyncImporter>? importers,
        PackageConfig? packageConfig,
        Iterable<String>? loadPaths,
        Iterable<AsyncCallable>? functions,
        OutputStyle? style,
        bool quietDeps = false,
        bool verbose = false,
        bool sourceMap = false}) =>
    c.compileAsync(path,
        logger: logger,
        importCache: AsyncImportCache(
            importers: importers,
            logger: logger ?? Logger.stderr(color: color),
            loadPaths: loadPaths,
            packageConfig: packageConfig),
        functions: functions,
        style: style,
        quietDeps: quietDeps,
        verbose: verbose,
        sourceMap: sourceMap);

/// Like [compileStringToResult], except it runs asynchronously.
///
/// Running asynchronously allows this to take [AsyncImporter]s rather than
/// synchronous [Importer]s. However, running asynchronously is also somewhat
/// slower, so [compileStringToResult] should be preferred if possible.
///
/// {@category Compile}
Future<CompileResult> compileStringToResultAsync(String source,
        {Syntax? syntax,
        bool color = false,
        Logger? logger,
        Iterable<AsyncImporter>? importers,
        PackageConfig? packageConfig,
        Iterable<String>? loadPaths,
        Iterable<AsyncCallable>? functions,
        OutputStyle? style,
        AsyncImporter? importer,
        Object? url,
        bool quietDeps = false,
        bool verbose = false,
        bool sourceMap = false,
        bool charset = true}) =>
    c.compileStringAsync(source,
        syntax: syntax,
        logger: logger,
        importCache: AsyncImportCache(
            importers: importers,
            logger: logger ?? Logger.stderr(color: color),
            packageConfig: packageConfig,
            loadPaths: loadPaths),
        functions: functions,
        style: style,
        importer: importer,
        url: url,
        quietDeps: quietDeps,
        verbose: verbose,
        sourceMap: sourceMap,
        charset: charset);

/// Like [compileToResult], but returns [CompileResult.css] rather than
/// returning [CompileResult] directly.
///
/// If [sourceMap] is passed, it's passed a [SingleMapping] that indicates which
/// sections of the source file(s) correspond to which in the resulting CSS.
/// It's called immediately before this method returns, and only if compilation
/// succeeds. Note that [SingleMapping.targetUrl] will always be `null`. Users
/// using the [SingleMapping] API should be sure to add the [`source_maps`][]
/// package to their pubspec.
///
/// [`source_maps`]: https://pub.dartlang.org/packages/source_maps
///
/// This parameter is meant to be used as an out parameter, so that users who
/// want access to the source map can get it. For example:
///
/// ```dart
/// SingleMapping sourceMap;
/// var css = compile(sassPath, sourceMap: (map) => sourceMap = map);
/// ```
///
/// {@category Compile}
@Deprecated("Use compileToResult() instead.")
String compile(
    String path,
    {bool color = false,
    Logger? logger,
    Iterable<Importer>? importers,
    Iterable<String>? loadPaths,
    PackageConfig? packageConfig,
    Iterable<Callable>? functions,
    OutputStyle? style,
    bool quietDeps = false,
    bool verbose = false,
    @Deprecated("Use CompileResult.sourceMap from compileToResult() instead.")
        void sourceMap(SingleMapping map)?,
    bool charset = true}) {
  var result = compileToResult(path,
      logger: logger,
      importers: importers,
      loadPaths: loadPaths,
      packageConfig: packageConfig,
      functions: functions,
      style: style,
      quietDeps: quietDeps,
      verbose: verbose,
      sourceMap: sourceMap != null,
      charset: charset);
  result.sourceMap.andThen(sourceMap);
  return result.css;
}

/// Like [compileStringToResult], but returns [CompileResult.css] rather than
/// returning [CompileResult] directly.
///
/// If [sourceMap] is passed, it's passed a [SingleMapping] that indicates which
/// sections of the source file(s) correspond to which in the resulting CSS.
/// It's called immediately before this method returns, and only if compilation
/// succeeds. Note that [SingleMapping.targetUrl] will always be `null`. Users
/// using the [SingleMapping] API should be sure to add the [`source_maps`][]
/// package to their pubspec.
///
/// [`source_maps`]: https://pub.dartlang.org/packages/source_maps
///
/// This parameter is meant to be used as an out parameter, so that users who
/// want access to the source map can get it. For example:
///
/// ```dart
/// SingleMapping sourceMap;
/// var css = compileString(sass, sourceMap: (map) => sourceMap = map);
/// ```
///
/// {@category Compile}
@Deprecated("Use compileStringToResult() instead.")
String compileString(
    String source,
    {Syntax? syntax,
    bool color = false,
    Logger? logger,
    Iterable<Importer>? importers,
    PackageConfig? packageConfig,
    Iterable<String>? loadPaths,
    Iterable<Callable>? functions,
    OutputStyle? style,
    Importer? importer,
    Object? url,
    bool quietDeps = false,
    bool verbose = false,
    @Deprecated("Use CompileResult.sourceMap from compileStringToResult() instead.")
        void sourceMap(SingleMapping map)?,
    bool charset = true,
    @Deprecated("Use syntax instead.")
        bool indented = false}) {
  var result = compileStringToResult(source,
      syntax: syntax ?? (indented ? Syntax.sass : Syntax.scss),
      logger: logger,
      importers: importers,
      packageConfig: packageConfig,
      loadPaths: loadPaths,
      functions: functions,
      style: style,
      importer: importer,
      url: url,
      quietDeps: quietDeps,
      verbose: verbose,
      sourceMap: sourceMap != null,
      charset: charset);
  result.sourceMap.andThen(sourceMap);
  return result.css;
}

/// Like [compile], except it runs asynchronously.
///
/// Running asynchronously allows this to take [AsyncImporter]s rather than
/// synchronous [Importer]s. However, running asynchronously is also somewhat
/// slower, so [compile] should be preferred if possible.
///
/// {@category Compile}
@Deprecated("Use compileToResultAsync() instead.")
Future<String> compileAsync(
    String path,
    {bool color = false,
    Logger? logger,
    Iterable<AsyncImporter>? importers,
    PackageConfig? packageConfig,
    Iterable<String>? loadPaths,
    Iterable<AsyncCallable>? functions,
    OutputStyle? style,
    bool quietDeps = false,
    bool verbose = false,
    @Deprecated("Use CompileResult.sourceMap from compileToResultAsync() instead.")
        void sourceMap(SingleMapping map)?}) async {
  var result = await compileToResultAsync(path,
      logger: logger,
      importers: importers,
      loadPaths: loadPaths,
      packageConfig: packageConfig,
      functions: functions,
      style: style,
      quietDeps: quietDeps,
      verbose: verbose,
      sourceMap: sourceMap != null);
  result.sourceMap.andThen(sourceMap);
  return result.css;
}

/// Like [compileString], except it runs asynchronously.
///
/// Running asynchronously allows this to take [AsyncImporter]s rather than
/// synchronous [Importer]s. However, running asynchronously is also somewhat
/// slower, so [compileString] should be preferred if possible.
///
/// {@category Compile}
@Deprecated("Use compileStringToResultAsync() instead.")
Future<String> compileStringAsync(
    String source,
    {Syntax? syntax,
    bool color = false,
    Logger? logger,
    Iterable<AsyncImporter>? importers,
    PackageConfig? packageConfig,
    Iterable<String>? loadPaths,
    Iterable<AsyncCallable>? functions,
    OutputStyle? style,
    AsyncImporter? importer,
    Object? url,
    bool quietDeps = false,
    bool verbose = false,
    @Deprecated("Use CompileResult.sourceMap from compileStringToResultAsync() instead.")
        void sourceMap(SingleMapping map)?,
    bool charset = true,
    @Deprecated("Use syntax instead.")
        bool indented = false}) async {
  var result = await compileStringToResultAsync(source,
      syntax: syntax ?? (indented ? Syntax.sass : Syntax.scss),
      logger: logger,
      importers: importers,
      packageConfig: packageConfig,
      loadPaths: loadPaths,
      functions: functions,
      style: style,
      importer: importer,
      url: url,
      quietDeps: quietDeps,
      verbose: verbose,
      sourceMap: sourceMap != null,
      charset: charset);
  result.sourceMap.andThen(sourceMap);
  return result.css;
}
