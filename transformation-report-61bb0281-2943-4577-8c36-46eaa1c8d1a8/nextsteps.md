# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

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

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues that were not surfaced as errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Even when a project builds successfully, some APIs may have changed behavior on non-Windows platforms. Review usage of the following common problem areas:

- `System.Drawing` (requires `libgdiplus` on Linux/macOS or replacement with a supported library)
- `Microsoft.Win32` registry APIs (not available on non-Windows)
- `System.Security.Permissions` (partially available or removed)
- COM interop and P/Invoke calls targeting Windows-specific native libraries

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to surface these issues.

## 5. Review NuGet Package Compatibility

Open the `.csproj` file and review all `<PackageReference>` entries. Confirm each package supports your target framework by checking [NuGet.org](https://www.nuget.org). Replace any packages that only support `net4x` with their cross-platform equivalents.

## 6. Validate Configuration Files

If the project previously relied on `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables as appropriate for .NET. The `System.Configuration.ConfigurationManager` NuGet package can provide backward compatibility if a full migration is not yet feasible.

## 7. Perform Runtime Smoke Testing

Run the application locally and exercise its primary functionality manually or through integration tests. Pay attention to:

- File path separators (`\` vs `/`) if the code constructs paths manually — use `Path.Combine` instead.
- Culture-sensitive string operations that may behave differently under the new runtime.
- Serialization and deserialization behavior if using `BinaryFormatter` (which is disabled by default in .NET 5+).

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that includes the .NET runtime:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (`linux-x64`, `osx-x64`, etc.) for your target environment. A full list of runtime identifiers is available in the [Microsoft RID catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).