# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`).

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

## 3. Review NuGet Package Compatibility

Check all NuGet dependencies in `AdoCore.csproj` to confirm they target .NET Standard 2.0+ or the specific .NET version you are using. Packages that still reference `net45` or older frameworks may cause unexpected behavior at runtime even if the build succeeds.

```bash
dotnet list package --outdated
```

Update any outdated packages as appropriate.

## 4. Run Existing Tests

If a test project exists in the solution, execute the test suite to verify functional correctness after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate behavioral differences between .NET Framework and modern .NET (e.g., changes in `System.Data`, threading, or globalization behavior).

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or review the code manually for any APIs that were available in .NET Framework but are not available or behave differently in cross-platform .NET. Common areas to check include:

- `System.Data` and ADO.NET provider registration (relevant given the `AdoCore` project name)
- `ConfigurationManager` usage (requires the `System.Configuration.ConfigurationManager` NuGet package)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific security or identity APIs

## 6. Validate ADO.NET Provider Registration

Since this project is named `AdoCore`, confirm that any database providers (e.g., SQL Server, Oracle, PostgreSQL) are explicitly registered in code, as automatic provider registration via `machine.config` is not available in cross-platform .NET:

```csharp
// Example for SQL Server
DbProviderFactories.RegisterFactory("System.Data.SqlClient", SqlClientFactory.Instance);
```

## 7. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent publish
dotnet publish --configuration Release --output ./publish

# Self-contained publish for a specific platform
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assemblies and configuration files are present before deploying to the target environment.