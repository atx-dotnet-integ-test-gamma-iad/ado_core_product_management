# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

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

Ensure there are no warnings that could indicate deprecated APIs or compatibility shims that may cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently on cross-platform .NET. Review the following areas manually:

- **`System.Data` and ADO.NET usage**: Since this project is named `AdoCore`, verify that all database providers (e.g., SQL Server, Oracle, OleDb) have compatible NuGet packages for .NET. Note that `System.Data.OleDb` is Windows-only and `System.Data.Odbc` has platform limitations.
- **Configuration**: Ensure `app.config` or `web.config` based configuration has been migrated to `appsettings.json` or `Microsoft.Extensions.Configuration` if applicable.
- **Connection strings**: Verify connection strings are correctly defined and accessible in the new configuration model.

## 5. Check for Windows-Only Dependencies

If cross-platform support is a goal, use the .NET Compatibility Analyzer to identify any Windows-only API calls:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Look for any `[SupportedOSPlatform("windows")]` warnings in the build output after adding this analyzer.

## 6. Review NuGet Package Versions

Open the `.csproj` file and confirm all NuGet packages reference current, stable versions compatible with your target framework. You can check for outdated packages with:

```bash
dotnet list package --outdated
```

Update packages where appropriate, particularly any that were previously targeting .NET Framework.

## 7. Validate Output and Behavior

Run the application manually or through integration tests against a real or test database to confirm:

- Connections open and close correctly.
- Queries return expected results.
- Transactions behave as expected.
- Exception handling paths work correctly.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assemblies and configuration files are present before deploying to the target environment.