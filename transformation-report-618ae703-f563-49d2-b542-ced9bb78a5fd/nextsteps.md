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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they are not hard errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time but appear at runtime. Pay attention to the following areas:

- **`System.Configuration`**: If the project previously used `ConfigurationManager` or `app.config`, ensure you have added the `System.Configuration.ConfigurationManager` NuGet package and migrated settings where appropriate.
- **ADO.NET Providers**: Since the project is named `AdoCore`, verify that the database provider (e.g., `System.Data.SqlClient` or `Microsoft.Data.SqlClient`) is explicitly referenced and functional on the target platform.
- **Platform-Specific APIs**: Any Windows-only APIs (e.g., registry access, COM interop) will fail on non-Windows platforms. Use the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to identify these.

## 5. Validate Database Connectivity

Given the ADO-related nature of the project, perform an end-to-end connectivity test against your target database to confirm that connection strings, authentication mechanisms, and query behavior work as expected under the new runtime.

## 6. Review NuGet Package Compatibility

Run the following command to check for outdated or potentially incompatible packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, prioritizing any that target `netstandard2.0` or older frameworks, as newer .NET-specific versions may be available.

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assemblies and configuration files are present before deploying to the target environment.