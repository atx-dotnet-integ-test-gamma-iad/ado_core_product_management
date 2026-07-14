# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been available in .NET Framework but behave differently or are unsupported on non-Windows platforms in cross-platform .NET. Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for such usage:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to:
- `System.Data` and ADO.NET provider usage (relevant given the `AdoCore` project name)
- Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage
- Any P/Invoke or COM interop calls

## 5. Validate Database Connectivity

Since the project name suggests ADO.NET core functionality, verify that all database drivers and connection strings are compatible with the target platform:

- Confirm NuGet packages for database providers (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) are referencing current, cross-platform compatible versions.
- Test actual database connections in a non-production environment to confirm connectivity and query behavior.

## 6. Review NuGet Package Versions

Check that all referenced NuGet packages support the target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update packages where newer versions provide better cross-platform support or security fixes.

## 7. Test on Target Operating Systems

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch any runtime issues that do not surface at compile time.

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the publish output directory to confirm all required files are present before deploying to the target environment.