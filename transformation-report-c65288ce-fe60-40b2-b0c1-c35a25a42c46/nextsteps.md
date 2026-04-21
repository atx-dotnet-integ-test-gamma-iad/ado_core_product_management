# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

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

Ensure there are no warnings that could indicate deprecated APIs or compatibility shims that may cause runtime issues.

## 3. Run Existing Tests

If a test project exists in the solution, execute the test suite to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time. Pay attention to the following areas that commonly differ between .NET Framework and modern .NET:

- **`System.Configuration`**: `ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package.
- **`System.Data`**: ADO.NET is available, but certain provider-specific behaviors may differ. Since this project is named `AdoCore`, verify all database provider packages (e.g., `Microsoft.Data.SqlClient`) are explicitly referenced and up to date.
- **Reflection and serialization**: Behavior differences exist in `BinaryFormatter` (removed in .NET 9) and certain reflection APIs.
- **Platform-specific APIs**: Any calls to Windows Registry, COM interop, or `System.Drawing` (GDI+) may require additional NuGet packages or may not function on non-Windows platforms.

## 5. Validate ADO.NET Functionality

Given the project name `AdoCore`, perform focused validation of all data access logic:

- Test all connection string configurations to ensure they resolve correctly in the new environment.
- Verify that database provider factory patterns (e.g., `DbProviderFactories.RegisterFactory`) are explicitly registered, as automatic registration from `machine.config` does not exist in cross-platform .NET.
- Execute integration tests against a real or test database instance if available.

## 6. Review NuGet Package Versions

Check that all NuGet packages referenced in `AdoCore.csproj` are current and compatible with the target framework:

```bash
dotnet list package --outdated
```

Update packages where appropriate, particularly any database drivers or data access libraries.

## 7. Test on Target Platform

If cross-platform support (Linux/macOS) is a goal, run the application on the intended non-Windows platform to surface any remaining platform-specific issues:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier:

```bash
# Framework-dependent (requires .NET runtime installed on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained (bundles the runtime)
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Review the contents of the `./publish` directory to confirm all expected files and dependencies are present before deploying to the target environment.