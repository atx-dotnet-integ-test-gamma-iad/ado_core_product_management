# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

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

Ensure there are no warnings that could indicate compatibility issues, such as deprecated APIs or platform-specific calls.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have changed behavior or may not be fully supported on non-Windows platforms. Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for potential runtime issues:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze
```

Pay particular attention to:
- `System.Data` and ADO.NET provider usage (relevant given the `AdoCore` project name)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific interop or COM references

## 5. Validate ADO.NET / Database Connectivity

Since the project is named `AdoCore`, confirm that any database drivers or providers used (e.g., `System.Data.SqlClient`, `Microsoft.Data.SqlClient`, `Npgsql`) are referencing the correct NuGet packages compatible with cross-platform .NET:

- Replace `System.Data.SqlClient` with `Microsoft.Data.SqlClient` if targeting SQL Server.
- Verify connection string formats have not changed.
- Run integration tests or a manual connection test against the target database.

## 6. Check NuGet Package Compatibility

Review all NuGet dependencies in `AdoCore.csproj` and confirm each package supports the target framework. You can use the following command to identify outdated or incompatible packages:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Update any packages flagged as incompatible or outdated.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime exceptions that would not appear at build time.

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment for Linux x64
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the output directory to confirm all required files and dependencies are present before deploying to the target environment.