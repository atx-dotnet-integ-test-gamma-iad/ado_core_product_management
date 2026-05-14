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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not produce build errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time. Pay attention to the following areas:

- **`System.Configuration`**: If the project previously used `App.config` or `ConfigurationManager`, ensure you have added the `System.Configuration.ConfigurationManager` NuGet package and migrated settings where appropriate.
- **`System.Data` and ADO.NET**: Since this project is named `AdoCore`, verify that all database provider packages (e.g., `Microsoft.Data.SqlClient`) are explicitly referenced and that connection string handling works as expected at runtime.
- **Platform-specific APIs**: Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a goal, and verify there are no `PlatformNotSupportedException` errors at runtime.

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` are compatible with the target framework. You can use the following command to identify outdated or potentially incompatible packages:

```bash
dotnet list package --outdated
```

Update packages where necessary using:

```bash
dotnet add package <PackageName> --version <LatestVersion>
```

## 6. Validate Database Connectivity

Since this project appears to be ADO.NET focused, perform an integration test against your target database to confirm:

- Connections open and close correctly.
- Queries return expected results.
- Transactions behave as expected.
- Any stored procedure calls function correctly.

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assemblies and configuration files are present before deploying to your target environment.