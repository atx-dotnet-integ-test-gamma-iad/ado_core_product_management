# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and test the migrated project before deploying it.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element references the intended cross-platform .NET version (e.g., `net8.0`). Example:

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

Review the output for any warnings about deprecated or unlisted packages and update them as needed using:

```bash
dotnet list package --outdated
dotnet add package <PackageName>
```

## 3. Build the Solution

Perform a full solution build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, as some may indicate compatibility concerns that did not produce hard errors.

## 4. Run Unit Tests

If the solution contains test projects, execute all tests to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully. Failures may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform .NET equivalents.

## 5. Validate Platform-Specific Behavior

If the original project relied on Windows-specific APIs (e.g., the registry, COM interop, `System.Drawing`, or WCF), verify that those code paths either have cross-platform alternatives in place or are guarded with runtime checks such as:

```csharp
if (OperatingSystem.IsWindows())
{
    // Windows-specific logic
}
```

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package to identify remaining platform-specific risks.

## 6. Test on Target Platforms

Run the application on each platform you intend to support (Windows, Linux, macOS) to catch any runtime issues that do not surface at compile time:

```bash
dotnet run --configuration Release
```

Pay particular attention to file path separators, line endings, environment variable access, and any use of `AppDomain` or reflection.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the relevant runtime identifier (e.g., `win-x64`, `osx-x64`). Review the publish output directory to confirm all required assets are present.

## 8. Review Configuration Files

Ensure that any `app.config` or `web.config` files have been migrated to `appsettings.json` or environment-based configuration where applicable. The legacy XML-based configuration system has limited support in cross-platform .NET.