# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that could not be resolved.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Review the output and confirm there are zero errors and review any warnings that may indicate compatibility concerns.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review test results and investigate any failures, as they may indicate behavioral differences introduced by the migration.

## 5. Check for Removed or Changed APIs

Some APIs available in .NET Framework are not available or have changed in cross-platform .NET. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility tools to scan for any runtime-level incompatibilities that would not surface as build errors.

Pay particular attention to:
- `System.Data` and ADO.NET-related APIs, given the `AdoCore` project name suggests database interaction
- Any usage of `System.Configuration.ConfigurationManager`, which requires the `System.Configuration.ConfigurationManager` NuGet package in cross-platform .NET
- Platform-specific APIs such as the Windows registry or COM interop

## 6. Validate Runtime Behavior

Run the application and exercise its core functionality manually or through integration tests. Confirm that database connections, queries, and any data access logic behave as expected on the target platform.

## 7. Review NuGet Package Versions

Open the `.csproj` file and review all `<PackageReference>` entries. Confirm that each package supports the target framework. Check [nuget.org](https://www.nuget.org) for any packages that may have newer versions with better cross-platform support.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

To publish a self-contained executable for a specific platform, specify a runtime identifier:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target environment, such as `linux-x64` or `osx-x64`.

## 9. Verify Published Output

Navigate to the `./publish` directory and confirm all expected files are present, then run the published output directly to validate it functions correctly outside of the development environment.