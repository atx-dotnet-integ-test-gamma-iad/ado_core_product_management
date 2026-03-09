# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If it is still referencing `net48` or any other `.NET Framework` TFM, update it accordingly and rebuild.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework. If any packages are flagged, check NuGet for updated versions that support the new TFM.

## 3. Build the Solution

Perform a full build to confirm there are no errors:

```bash
dotnet build --configuration Release
```

Address any warnings that surface at this stage, particularly those related to nullable reference types or obsolete API usage, as these can indicate compatibility issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures may indicate behavioral differences between .NET Framework and cross-platform .NET, such as changes in globalization, string handling, or file path conventions.

## 5. Check Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any APIs that are Windows-only or otherwise platform-restricted:

```bash
dotnet add package Microsoft.Windows.Compatibility
```

If cross-platform support is required, replace or abstract any Windows-specific calls (e.g., registry access, certain `System.Drawing` APIs, WCF server-side hosting).

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS as applicable) and verify:

- File path handling uses `Path.Combine` and `Path.DirectorySeparatorChar` rather than hardcoded backslashes.
- Configuration files are read correctly using `Microsoft.Extensions.Configuration` rather than `ConfigurationManager` where applicable.
- Any database connection strings or external service endpoints are correctly resolved in the new environment.

## 7. Review Removed or Changed APIs

Cross-platform .NET removes or changes certain APIs that existed in .NET Framework. Review the official Microsoft migration guide for any APIs relevant to this project:

- [.NET Framework to .NET migration guide](https://learn.microsoft.com/en-us/dotnet/core/porting/)
- [Compatibility breaks between .NET Framework and .NET](https://learn.microsoft.com/en-us/dotnet/core/compatibility/fx-core)

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (`linux-x64`, `osx-x64`, etc.) for your target environment. A full list of runtime identifiers is available at the [.NET RID catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).