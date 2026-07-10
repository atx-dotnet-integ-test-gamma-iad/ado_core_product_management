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

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs behave differently or are unsupported on non-Windows platforms. Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for potential runtime issues:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to:
- `System.Data` and ADO.NET provider usage (relevant given the `AdoCore` project name)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions

## 5. Validate ADO.NET / Database Connectivity

Since the project is named `AdoCore`, confirm that any database drivers or providers referenced (e.g., `System.Data.SqlClient`, `Microsoft.Data.SqlClient`, or third-party drivers) are compatible with the target .NET version. `System.Data.SqlClient` is largely superseded by `Microsoft.Data.SqlClient` in modern .NET:

```xml
<PackageReference Include="Microsoft.Data.SqlClient" Version="5.x.x" />
```

Run integration or connection tests against your target database to confirm connectivity and query behavior.

## 6. Review NuGet Package Versions

Inspect `AdoCore.csproj` for any NuGet packages that were carried over from the legacy project. Ensure all packages have versions compatible with your target framework. You can check for outdated packages with:

```bash
dotnet list package --outdated
```

Update packages as needed, then rebuild and retest.

## 7. Validate Configuration Files

If the project previously relied on `App.config` or `Web.config`, confirm that configuration has been migrated to `appsettings.json` or environment variables, which are the standard configuration mechanisms in modern .NET.

## 8. Perform Runtime Smoke Testing

Run the application in a controlled environment and exercise its primary code paths. Check application logs for any runtime exceptions that would not have surfaced during compilation, such as:
- Missing configuration values
- Unsupported platform exceptions
- Reflection-based failures

## 9. Deploy to Target Environment

Once all validation steps pass, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Copy the contents of the `./publish` directory to your target environment and verify the application starts and operates correctly there.