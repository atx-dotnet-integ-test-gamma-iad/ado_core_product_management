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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not block the build.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior has not changed after migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time but appear at runtime. Pay attention to the following areas:

- **Reflection-based code**: Behavior can differ between .NET Framework and modern .NET.
- **Configuration**: `System.Configuration.ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package on modern .NET. Verify any `app.config` or `web.config` usage has been accounted for.
- **Platform-specific APIs**: Any Windows-only APIs (e.g., registry access, COM interop, WCF) will not work on non-Windows platforms. If cross-platform support is required, these will need to be replaced or conditionally compiled.

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` are compatible with the target framework. Use the following command to identify any potential issues:

```bash
dotnet list package --outdated
```

Update packages where necessary, prioritizing any that were carried over from the legacy project.

## 6. Validate ADO.NET Data Access

Since the project name suggests ADO.NET usage (`AdoCore`), verify the following:

- The correct database driver NuGet package is referenced (e.g., `Microsoft.Data.SqlClient` instead of the legacy `System.Data.SqlClient` where applicable).
- Connection strings are being read from the correct configuration source (e.g., `appsettings.json` rather than `app.config` if applicable).
- Any `DataSet`, `DataTable`, or `DataAdapter` usage functions correctly, as these are supported but some edge-case behaviors may differ.

## 7. Publish the Application

Once validation is complete, publish the application using the following command:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all expected assemblies and configuration files are present before deploying to the target environment.