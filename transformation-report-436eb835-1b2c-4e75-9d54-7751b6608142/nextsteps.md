# Next Steps

The solution has no build errors following the transformation. The steps below cover validation and deployment of the migrated project.

## 1. Review the Migrated Project File

Open `AdoCore.csproj` and confirm the following:

- The `<TargetFramework>` element targets a supported cross-platform .NET version, such as `net8.0`.
- Any remaining `<Reference>` elements that previously pointed to Windows-only assemblies (e.g., `System.Web`, `System.Windows.Forms`) have been replaced with appropriate NuGet packages or removed.
- NuGet package versions are current and compatible with the target framework.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all packages are restored cleanly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating them in the `.csproj` file.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Review any warnings produced during the build, particularly those related to nullable reference types, obsolete APIs, or platform compatibility analyzers (`CA1416`), as these may indicate runtime issues on non-Windows platforms.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify behavioral correctness after migration:

```bash
dotnet test --configuration Release
```

If no tests currently exist, consider writing unit tests that cover the core functionality of `AdoCore` before proceeding to deployment.

## 5. Validate Platform Compatibility

If the intent is to run this project on Linux or macOS, test it explicitly on those platforms. Pay particular attention to:

- File path handling (use `Path.Combine` rather than hardcoded separators).
- Any ADO.NET connection strings or database drivers that may require platform-specific configuration.
- Any P/Invoke calls or COM interop that will not function outside of Windows.

## 6. Check Runtime Behavior

Run the application (or a representative integration test) against a real or representative data source to confirm that ADO.NET operations — connections, commands, queries, and transactions — behave correctly under the new runtime.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the project for the target platform. The following example publishes a self-contained executable for Linux x64:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Adjust the `--runtime` identifier to match your deployment target (e.g., `win-x64`, `osx-x64`, `linux-arm64`). Review the output in the `publish` folder before deploying to the target environment.