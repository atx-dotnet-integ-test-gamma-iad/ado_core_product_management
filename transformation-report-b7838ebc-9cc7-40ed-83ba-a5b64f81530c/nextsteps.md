# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this is consistent with any dependent or consuming projects in the solution.

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not cause build failures.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior has not changed after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Runtime-Only Issues

Some APIs that compiled successfully may behave differently or throw exceptions at runtime on cross-platform .NET. Pay particular attention to:

- **File path handling**: Ensure no hardcoded Windows-style paths (`\`) are used. Prefer `Path.Combine()`.
- **Registry access**: `Microsoft.Win32.Registry` is not supported on Linux/macOS.
- **Windows-specific APIs**: Any P/Invoke calls or `[DllImport]` attributes targeting Windows-only DLLs will fail on non-Windows platforms.
- **`System.Configuration.ConfigurationManager`**: If used, ensure the `System.Configuration.ConfigurationManager` NuGet package is referenced.
- **`AppDomain`**: Some members are no longer supported and will throw `PlatformNotSupportedException`.

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` have versions that support your target framework. You can audit this with:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update any packages that have newer, compatible versions available.

## 6. Validate ADO-Specific Functionality

Since the project is named `AdoCore`, it likely involves data access. Verify the following:

- The database provider packages (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, etc.) are up to date and compatible with the target framework.
- Connection strings and data access logic function correctly against your target database.
- Any use of `System.Data.OleDb` is noted, as it is only supported on Windows in .NET Core/.NET 5+.

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assemblies and configuration files are present before deploying to your target environment.