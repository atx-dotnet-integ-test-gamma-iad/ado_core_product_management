# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

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

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Runtime Behavioral Differences

Cross-platform .NET may behave differently from .NET Framework in the following areas. Manually verify these if they are relevant to your project:

- **File path separators**: Ensure no hardcoded backslashes (`\`) are used where forward slashes or `Path.Combine` should be used instead.
- **Registry access**: `Microsoft.Win32.Registry` is Windows-only. If your code uses it, add a Windows runtime check or replace it with a cross-platform alternative.
- **`System.Drawing`**: This namespace has limited support on non-Windows platforms. Consider replacing it with a cross-platform library such as `SkiaSharp` if cross-platform rendering is required.
- **`ConfigurationManager`**: If used, ensure the `System.Configuration.ConfigurationManager` NuGet package is referenced, or migrate to `Microsoft.Extensions.Configuration`.
- **Thread culture and encoding defaults**: These may differ from .NET Framework defaults. Verify any locale-sensitive or encoding-sensitive logic.

## 5. Review NuGet Package Compatibility

Open the `.csproj` file and review all `<PackageReference>` entries. Check that each package supports your target framework by visiting [nuget.org](https://www.nuget.org) and confirming `.NET 6`/`.NET 8` compatibility. Replace or remove any packages that only support `net45` or `netstandard1.x` where a newer alternative exists.

## 6. Validate Platform-Specific Behavior on Target OS

If the application is intended to run on Linux or macOS, test it directly on those platforms:

```bash
dotnet run --configuration Release
```

Pay attention to file system case sensitivity, line endings, and OS-specific API calls.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

**Windows:**
```bash
dotnet publish -c Release -r win-x64 --self-contained false
```

**Linux:**
```bash
dotnet publish -c Release -r linux-x64 --self-contained false
```

Use `--self-contained true` if you want to bundle the .NET runtime with the output.

## 8. Verify Published Output

Navigate to the publish output directory (typically `bin/Release/net8.0/<rid>/publish/`) and confirm that all expected assemblies, configuration files, and static assets are present before deploying to the target environment.