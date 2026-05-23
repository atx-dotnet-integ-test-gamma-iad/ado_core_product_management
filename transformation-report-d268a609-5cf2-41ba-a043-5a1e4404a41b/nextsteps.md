# Next Steps

The solution has no build errors following the transformation. The steps below cover validation and deployment of the migrated project.

## 1. Review the Migrated Project File

Open `AdoCore.csproj` and confirm the following:

- The `<TargetFramework>` element targets a supported cross-platform .NET version, for example `net8.0`.
- Any remaining `<Reference>` elements that previously pointed to Windows-only assemblies (e.g., `System.Web`, `System.Windows.Forms`) have been replaced with appropriate NuGet packages or removed if no longer needed.
- `<PackageReference>` entries are present in place of any old `packages.config` dependencies.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating them to their current stable versions using:

```bash
dotnet list package --outdated
dotnet add package <PackageName>
```

## 3. Build the Solution

Perform a clean build to confirm there are no issues introduced by the restored packages:

```bash
dotnet build --configuration Release
```

Review any warnings in the build output. While warnings do not block the build, they may indicate API usage that is obsolete in modern .NET and should be addressed.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

- Confirm all previously passing tests continue to pass.
- Investigate any failures, as they may indicate behavioral differences between .NET Framework and modern .NET (e.g., changes in `System.Text.Encoding`, threading defaults, or globalization behavior).

## 5. Check for Platform-Specific Code

Search the codebase for APIs that may behave differently or are unavailable on non-Windows platforms:

- `Registry` access (`Microsoft.Win32.Registry`)
- `System.Drawing` (requires the `System.Drawing.Common` package and may have limitations on Linux/macOS)
- P/Invoke calls to Windows-specific native libraries
- `AppDomain.CreateDomain` (not supported in .NET Core and later)

Address each occurrence by either replacing it with a cross-platform alternative or conditionally compiling it using runtime checks such as `RuntimeInformation.IsOSPlatform`.

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS as applicable) and exercise the primary code paths:

```bash
dotnet run --configuration Release
```

Pay particular attention to:

- File path handling (use `Path.Combine` rather than hardcoded separators)
- Configuration file loading (migrate from `App.config`/`Web.config` to `appsettings.json` with `Microsoft.Extensions.Configuration` if not already done)
- Serialization behavior differences between `Newtonsoft.Json` and `System.Text.Json` if a migration between the two occurred

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime:

**Framework-dependent (requires .NET runtime installed on the target machine):**

```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the runtime with the application):**

```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, `osx-arm64`, etc.) as needed.

Verify the contents of the `./publish` directory and confirm the application runs correctly from that location before distributing it.