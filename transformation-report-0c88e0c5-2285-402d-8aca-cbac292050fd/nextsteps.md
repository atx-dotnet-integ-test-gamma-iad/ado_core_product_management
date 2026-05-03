# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
</Project>
```

## 2. Restore and Build the Solution

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues that were not caught as errors.

## 3. Review NuGet Package Versions

Check that all NuGet dependencies in `AdoCore.csproj` are referencing versions compatible with your target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available, particularly those that may have had separate .NET Framework and .NET Core variants.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and modern .NET.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been silently replaced or may throw `PlatformNotSupportedException` at runtime. Specifically review any code that previously relied on:

- `System.Data` and ADO.NET provider-specific classes (given the `AdoCore` project name, this is particularly relevant)
- Windows Registry access
- `System.Web` namespaces
- COM interop or P/Invoke calls

Run the .NET Upgrade Assistant compatibility analyzer if you have not already done so:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <path-to-solution>
```

## 6. Validate ADO.NET Database Connectivity

Since this project appears to be ADO.NET-focused, perform an integration test against your target database to confirm:

- Connection strings are valid and compatible with the new runtime
- The correct database driver NuGet package is referenced (e.g., `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient` for SQL Server)
- Transactions, commands, and data readers behave as expected

## 7. Test on Target Operating System

If cross-platform support was a goal of this migration, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a build.

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your target runtime identifier (e.g., `win-x64`, `osx-x64`). Use `--self-contained true` if you want to bundle the .NET runtime with the output.