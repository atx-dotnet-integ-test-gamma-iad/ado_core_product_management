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

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework. Replace any packages that only support `.NETFramework` with their cross-platform equivalents if warnings are present.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the build output for any warnings that may indicate compatibility concerns, even if they do not cause outright failures.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully. Failures may indicate behavioral differences between .NET Framework and modern .NET, such as changes in:

- `System.Configuration` usage
- `HttpClient` behavior
- Reflection APIs
- Globalization and encoding defaults

## 5. Check for Runtime-Specific Behavior

Even with a clean build, certain areas require manual validation at runtime:

- **Database connectivity**: If `AdoCore` implies ADO.NET usage, verify that the database drivers (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) are cross-platform compatible and correctly referenced.
- **Connection strings**: Ensure connection strings are sourced from a cross-platform configuration mechanism such as `appsettings.json` or environment variables, rather than `app.config` or `web.config` where applicable.
- **File paths**: Confirm that any hardcoded file paths use `Path.Combine` or `Path.DirectorySeparatorChar` rather than backslashes.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific issues:

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application for deployment:

```bash
dotnet publish --configuration Release --output ./publish
```

If a self-contained deployment is required (no .NET runtime needed on the target machine):

```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) for your target environment. A full list of runtime identifiers is available in the [.NET RID catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).