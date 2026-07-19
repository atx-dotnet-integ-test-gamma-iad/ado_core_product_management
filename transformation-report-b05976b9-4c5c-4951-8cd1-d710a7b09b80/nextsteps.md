# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If you require multi-targeting, ensure it is expressed as:

```xml
<TargetFrameworks>net8.0;net472</TargetFrameworks>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not cause build failures.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time. Pay attention to the following areas:

- **Reflection-based code**: Behavior differences may exist between .NET Framework and modern .NET.
- **Configuration**: `System.Configuration.ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package if used.
- **Windows-specific APIs**: Any APIs marked with `[SupportedOSPlatform("windows")]` will throw `PlatformNotSupportedException` on non-Windows systems.
- **Database connectivity**: If `AdoCore` implies ADO.NET usage, verify that the correct database driver NuGet packages are referenced (e.g., `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient`).

## 5. Validate ADO.NET Functionality Specifically

Given the project name `AdoCore`, confirm the following:

- Connection strings are sourced correctly under the new configuration system.
- Any `DataAdapter`, `DataSet`, or `DataTable` usage functions as expected, as these are supported but some edge-case behaviors differ.
- If `System.Data.OleDb` or `System.Data.Odbc` is used, note that these are Windows-only on modern .NET and will require the corresponding NuGet packages.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Refer to the [.NET publish documentation](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-publish) for additional options such as single-file publishing and trimming.