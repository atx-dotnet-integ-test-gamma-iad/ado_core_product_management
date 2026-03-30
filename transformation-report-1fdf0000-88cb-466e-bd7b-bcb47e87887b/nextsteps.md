# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime environment you intend to deploy to.

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

If the solution contains test projects, execute them to verify that runtime behavior matches the original:

```bash
dotnet test --configuration Release
```

Pay attention to any tests that were previously passing in the legacy project but may now fail due to behavioral differences between .NET Framework and modern .NET (e.g., changes in `System.Data`, threading, or serialization).

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time but appear at runtime. Manually exercise the core functionality of `AdoCore`, particularly any database access logic (ADO.NET connections, commands, data readers), as ADO.NET behavior can differ subtly between .NET Framework and modern .NET, especially around:

- Connection string handling
- Provider factory registration (e.g., `DbProviderFactories.RegisterFactory`)
- `DataSet` and `DataTable` serialization

## 5. Review NuGet Package Compatibility

Open the `.csproj` file and review all `<PackageReference>` entries. Confirm that each package version explicitly supports your target framework. You can verify this on [nuget.org](https://www.nuget.org) or by running:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with improved cross-platform support.

## 6. Validate Platform-Specific Code

Search the codebase for any APIs that were available in .NET Framework but are not fully supported in modern .NET, such as:

- `System.Configuration.ConfigurationManager` (requires the `System.Configuration.ConfigurationManager` NuGet package)
- `System.Drawing` (requires the `System.Drawing.Common` package and may have OS restrictions)
- COM interop or Windows Registry access

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining compatibility concerns.

## 7. Test on Target Operating System

If cross-platform support (Linux/macOS) is a goal, run the application on the intended non-Windows OS to catch any platform-specific runtime failures that would not appear on Windows.

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier:

```bash
# Framework-dependent (requires .NET runtime installed on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained (bundles the runtime)
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Review the contents of the `./publish` directory to confirm all expected files and dependencies are present before deploying to the target environment.