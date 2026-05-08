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

Ensure there are no warnings that could indicate compatibility issues, such as deprecated APIs or platform-specific code paths.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have changed behavior or may not be fully supported on non-Windows platforms. Review usage of the following common areas:

- `System.Data` and ADO.NET providers (relevant given the `AdoCore` project name)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (e.g., backslash separators)
- `System.Security` and cryptography APIs
- COM interop or P/Invoke calls

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package if needed.

## 5. Validate ADO.NET / Database Connectivity

Since the project is named `AdoCore`, confirm that the database driver NuGet packages are explicitly referenced and compatible with the target framework. For example:

- SQL Server: `Microsoft.Data.SqlClient`
- SQLite: `Microsoft.Data.Sqlite`
- Other providers: verify the NuGet package supports `netstandard2.0` or your specific target framework

Test actual database connections in a non-production environment to confirm connectivity and query behavior.

## 6. Review NuGet Package Versions

Ensure all NuGet dependencies are up to date and do not reference packages that target only `net4x`:

```bash
dotnet list package --outdated
```

Update packages where appropriate, and review any that have no cross-platform equivalent.

## 7. Test on Target Platforms

If cross-platform support (Linux, macOS) is a goal, run the application on each intended platform to catch any runtime issues not surfaced during the build:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment for a specific platform
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying to the target environment.