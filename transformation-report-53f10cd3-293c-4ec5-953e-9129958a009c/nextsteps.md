# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not produce build errors.

## 3. Review NuGet Package Versions

Open the `.csproj` file and inspect all `<PackageReference>` entries. Ensure each package:
- Has a version compatible with your target framework.
- Is not a package that was previously only available for .NET Framework (e.g., some older `System.*` packages may need to be removed as they are now part of the runtime).

Use the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

## 4. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently on cross-platform .NET compared to .NET Framework. Pay particular attention to:
- **`System.Data`** and ADO.NET-related types, since this project appears to be ADO-related (`AdoCore`). Verify that database provider packages (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, etc.) are explicitly referenced and up to date.
- Any use of `System.Configuration.ConfigurationManager` — this requires the `System.Configuration.ConfigurationManager` NuGet package on modern .NET.
- Any use of `System.Drawing` — this requires the `System.Drawing.Common` package and has platform restrictions on non-Windows systems.

## 5. Run Existing Tests

If a test project exists in the solution, execute the tests to validate runtime behavior:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may surface runtime differences between .NET Framework and modern .NET.

## 6. Perform Manual Functional Testing

Since this project appears to be a data access core library, manually exercise the following scenarios:
- Opening and closing database connections.
- Executing queries and reading results via `DataReader` or `DataSet`.
- Transaction handling (commit and rollback).
- Exception handling for database errors.

Test these against all database providers your application supports.

## 7. Validate Platform Compatibility

If cross-platform support (Linux, macOS) is a goal, run the application or tests on the target operating systems to surface any platform-specific issues. Pay attention to:
- File path separators.
- Case sensitivity in file and database object names.
- Any P/Invoke or native interop calls that may not be supported on non-Windows platforms.

## 8. Publish the Project

Once validation is complete, publish the project using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` folder to confirm all required assemblies and dependencies are present before deploying to your target environment.