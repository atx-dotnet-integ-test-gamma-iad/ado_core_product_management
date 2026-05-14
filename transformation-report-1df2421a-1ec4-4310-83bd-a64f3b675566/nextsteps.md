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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Review NuGet Package Versions

Open the `.csproj` file and check that all `<PackageReference>` entries reference versions compatible with your target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available, particularly those that were previously targeting .NET Framework.

## 4. Check for Removed or Changed APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tool to identify any APIs used in the code that have been removed or changed in the target .NET version:

```bash
dotnet tool install -g dotnet-apicompat
```

Pay particular attention to:
- `System.Web` usages (not available in cross-platform .NET)
- Windows-specific APIs (e.g., registry access, WCF server-side)
- Any ADO.NET-specific behavior differences if this project involves data access

## 5. Run Existing Tests

If a test project exists in the solution, execute the tests to verify runtime behavior:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output for any failed or skipped tests. Address any failures before proceeding.

## 6. Perform Runtime Smoke Testing

Run the application locally and exercise its primary code paths manually or via integration tests:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Confirm that:
- Database connections (if applicable) function correctly
- No `PlatformNotSupportedException` or `NotImplementedException` is thrown at runtime
- Logging and configuration systems initialize as expected

## 7. Validate on Target Operating Systems

Since the goal is cross-platform compatibility, test the build output on each intended operating system (Windows, Linux, macOS) if applicable:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Run the published output on the target OS and confirm there are no platform-specific runtime errors.

## 8. Review Configuration Files

Ensure that any configuration previously stored in `App.config` or `Web.config` has been migrated to `appsettings.json` or environment variables, as the `ConfigurationManager` behavior differs in cross-platform .NET.

## 9. Check Assembly and Namespace References

Confirm that any reflection-based code, assembly loading, or dynamic type resolution still functions correctly, as assembly naming conventions and loading behavior changed between .NET Framework and cross-platform .NET.