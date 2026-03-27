# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts. If any packages reference old `net4x` or Windows-only libraries, consider finding cross-platform equivalents on [NuGet](https://www.nuget.org).

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the build output for any warnings that may indicate compatibility concerns even if the build succeeds.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Pay close attention to any tests that exercise platform-specific functionality such as file paths, registry access, or Windows APIs, as these may fail on non-Windows platforms.

## 5. Validate Cross-Platform Behavior

If cross-platform support is a goal, run the application or tests on each target platform (Linux, macOS, Windows) to surface any runtime issues not caught at compile time. Common areas to check include:

- **File path separators**: Use `Path.Combine` and `Path.DirectorySeparatorChar` rather than hardcoded backslashes.
- **Environment variables**: Verify any environment variable assumptions hold on each OS.
- **Case sensitivity**: Linux file systems are case-sensitive; ensure file and directory references use consistent casing.

## 6. Review Nullable Reference Types

If the project has `<Nullable>enable</Nullable>` in the `.csproj`, review any new nullable warnings introduced during transformation. Address them by adding appropriate null checks or null-forgiving operators where the logic is verified safe.

## 7. Check for Removed or Changed APIs

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to identify any API usage that is Windows-only or otherwise restricted in the new target framework.

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

## 8. Publish the Application

Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your intended runtime identifier (e.g., `win-x64`, `osx-x64`). Review the output directory to confirm all required assets are present before deploying to the target environment.