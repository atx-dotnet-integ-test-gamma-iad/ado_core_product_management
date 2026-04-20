# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that could not be resolved.

## 3. Build the Solution

Perform a full build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review all test results and investigate any failures before proceeding.

## 5. Validate Platform-Specific Behavior

Since this is a cross-platform migration, run the application on each target operating system (Windows, Linux, macOS) if applicable. Pay particular attention to:

- File path separators (`\` vs `/`)
- Environment variable access
- Any calls to Windows-specific APIs (e.g., registry access, COM interop, `System.Windows.Forms`)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package to identify remaining platform-specific code.

## 6. Check for Removed or Changed APIs

Review the code for any usage of APIs that were removed or significantly changed between .NET Framework and modern .NET. The [.NET API compatibility tool](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/api-analyzer) (`Microsoft.DotNet.ApiCompat`) can assist with this.

Common areas to check:
- `System.Web` usage (not available in .NET Core/.NET 5+)
- `AppDomain` usage
- Binary serialization (`BinaryFormatter` is obsolete)
- `ConfigurationManager` (requires `System.Configuration.ConfigurationManager` NuGet package)

## 7. Review NuGet Package Versions

Ensure all NuGet packages referenced in `AdoCore.csproj` are up to date and compatible with the target framework:

```bash
dotnet list package --outdated
```

Update packages where appropriate, and verify that no packages still target .NET Framework exclusively.

## 8. Publish the Application

Once validation is complete, publish the application using the following command, adjusting the runtime identifier (`-r`) as needed:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment:

```bash
dotnet publish --configuration Release --self-contained true -r win-x64 --output ./publish
```

Verify the contents of the `./publish` directory and confirm the application runs correctly from that location.