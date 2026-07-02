# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime version installed on your machine.

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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they are not hard errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior has not changed after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform .NET equivalents.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may compile successfully but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Pay particular attention to areas such as:
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific UI frameworks
- COM interop
- `System.Drawing` (requires `System.Drawing.Common` on non-Windows)

## 5. Review NuGet Package Versions

Open the `.csproj` file and review all `<PackageReference>` entries. Ensure that each package version supports your target framework. You can check compatibility on [nuget.org](https://www.nuget.org).

```bash
dotnet list package --outdated
```

Update packages where appropriate:

```bash
dotnet add package <PackageName> --version <NewVersion>
```

## 6. Validate Configuration Files

If the project previously used `App.config` or `Web.config`, verify that settings have been migrated to the appropriate .NET configuration system, typically `appsettings.json` with `Microsoft.Extensions.Configuration`.

## 7. Perform Runtime Validation

Run the application and exercise its primary workflows manually or through integration tests. Confirm that:
- All data access operations function correctly
- External service connections are established as expected
- Logging and error handling behave as intended

## 8. Publish the Application

Once runtime validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) depending on your deployment target.

Review the contents of the publish output directory to confirm all required files and dependencies are present before deploying.