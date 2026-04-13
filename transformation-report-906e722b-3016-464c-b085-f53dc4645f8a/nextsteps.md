# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Platform-Specific Code

Search the codebase for any APIs that were Windows-specific in the legacy project, such as:

- `System.Windows.Forms`
- `Microsoft.Win32` registry access
- COM interop calls
- `System.Drawing` (GDI+)

These may compile without errors but fail at runtime on non-Windows platforms. Use the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to assist with this.

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` have versions compatible with your target framework. Run:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 6. Validate Configuration Files

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables where appropriate, as `ConfigurationManager` behavior differs in cross-platform .NET.

## 7. Runtime Validation

Run the application in your target environment and exercise the primary workflows. Pay particular attention to:

- File path separators (`/` vs `\`)
- Environment variable access
- Database connection strings and ADO.NET provider registration (relevant given the `AdoCore` project name)

For ADO.NET specifically, confirm that the required database provider (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) is explicitly referenced, as automatic provider discovery from `App.config` is not supported in cross-platform .NET.

```csharp
// Example: Ensure providers are registered in code if needed
DbProviderFactories.RegisterFactory("Microsoft.Data.SqlClient", SqlClientFactory.Instance);
```

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment target.