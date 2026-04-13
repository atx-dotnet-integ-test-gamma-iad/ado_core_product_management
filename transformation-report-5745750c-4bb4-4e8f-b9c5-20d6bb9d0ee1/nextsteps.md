# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime environment you plan to deploy to.

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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not produce errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time but appear at runtime. Run the application and exercise its core functionality, paying attention to:

- **Data access**: ADO.NET connection strings and database drivers may need to be updated. Ensure the appropriate NuGet packages (e.g., `Microsoft.Data.SqlClient`) are referenced instead of legacy `System.Data.SqlClient` where applicable.
- **Configuration**: If the project previously used `App.config` or `Web.config`, verify that configuration has been migrated to `appsettings.json` or environment variables as appropriate.
- **Platform-specific APIs**: Any calls to Windows-only APIs (e.g., registry access, COM interop) will fail on non-Windows platforms. Use `RuntimeInformation.IsOSPlatform` guards if cross-platform support is required.

## 5. Review NuGet Package Compatibility

Check that all NuGet dependencies are compatible with your target framework. Run the following to identify any outdated or incompatible packages:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Update packages as needed using:

```bash
dotnet add package <PackageName> --version <LatestVersion>
```

## 6. Validate ADO.NET Functionality Specifically

Given the project name `AdoCore`, confirm that all database operations function correctly:

- Test all connection, command, and data reader operations against your target database.
- Verify that any `DbProviderFactory` usage is explicitly registered, as automatic provider discovery from `App.config` is not supported in .NET Core and later.

```csharp
DbProviderFactories.RegisterFactory("System.Data.SqlClient", SqlClientFactory.Instance);
```

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory and confirm all required assets and dependencies are present before deploying to the target environment.