# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
</Project>
```

## 2. Restore and Build

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues.

## 3. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` are compatible with your target framework. Run:

```bash
dotnet list package --outdated
```

Update any outdated packages that have stable releases targeting your chosen framework version.

## 4. Run Existing Tests

If a test project exists in the solution, execute the test suite to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests to determine whether they are caused by behavioral differences between .NET Framework and modern .NET (e.g., changes in `System.Data`, threading, or globalization).

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs may have changed behavior on non-Windows platforms. Review any usage of:

- `System.Data` (ADO.NET) — confirm your database driver (e.g., `Microsoft.Data.SqlClient`) is referenced instead of the older `System.Data.SqlClient` where applicable.
- Registry, COM interop, or Windows-specific APIs — these will fail at runtime on non-Windows systems.
- `ConfigurationManager` — ensure `System.Configuration.ConfigurationManager` NuGet package is referenced if used.

## 6. Validate Runtime Behavior

Run the application in your target environment and exercise the primary workflows, particularly any database connectivity or data access logic given the ADO-related project name. Confirm:

- Connection strings are correctly configured for the new environment.
- Any `app.config` or `web.config` settings have been migrated to `appsettings.json` if applicable.

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required assemblies and configuration files are present before deploying to the target environment.