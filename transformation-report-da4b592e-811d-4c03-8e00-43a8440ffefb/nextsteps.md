# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Check that all NuGet dependencies referenced in `AdoCore.csproj` are compatible with the target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Check for Removed or Changed APIs

Review any usages of APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. Pay particular attention to:

- `System.Data` and ADO.NET-related types, since this appears to be a data-access project.
- Any Windows-specific APIs (e.g., registry access, `System.Drawing` without the compatibility package).
- Configuration APIs that previously relied on `System.Configuration.ConfigurationManager` — ensure the `System.Configuration.ConfigurationManager` NuGet package is referenced if needed.

## 5. Run Existing Tests

If a test project exists in the solution, execute the test suite:

```bash
dotnet test --configuration Release
```

Review any failing tests and resolve issues related to behavioral differences between .NET Framework and cross-platform .NET.

## 6. Perform Runtime Validation

Run the application or exercise the library's primary functionality manually or through integration tests. Confirm that:

- Database connections open and close correctly.
- Queries return expected results.
- Exceptions are handled as expected.

## 7. Validate on Target Operating Systems

Since the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to identify any platform-specific runtime issues:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the project using the appropriate runtime identifier for your target platform:

```bash
# For Linux x64
dotnet publish -c Release -r linux-x64 --self-contained true

# For Windows x64
dotnet publish -c Release -r win-x64 --self-contained true

# Framework-dependent (requires .NET runtime installed on target)
dotnet publish -c Release
```

Review the output in the `publish` folder and verify all required files are present before deploying to the target environment.